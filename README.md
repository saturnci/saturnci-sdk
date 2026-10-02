# saturnci-sdk

The Ruby SDK for [SaturnCI](https://www.saturnci.com/).

On SaturnCI, a CI/CD pipeline is a Ruby file called a **workflow**. SaturnCI
runs that file whenever something happens to a commit's pipeline, and the file
decides what should happen next: run the tests, build an image, deploy. This
gem is what the workflow file is written against.

## How a workflow runs

A workflow lives in your repository at `.saturnci/workflows/default_workflow.rb`.

When you push a commit, SaturnCI creates a **workflow run** for it and
evaluates your workflow: it runs the file in a container that already has this
gem installed, with the workflow run's id in the environment. The file is a
plain Ruby script; SaturnCI simply executes it.

SaturnCI evaluates the workflow again every time a job in that workflow run
finishes, and periodically while the run is still going. Each evaluation is a
fresh process. Your file does not wait for anything; it looks at the current
state of the workflow run, starts whatever is now ready to start, and exits.
Once the pipeline is complete, it tells SaturnCI the workflow run is finished.

Because the same file is evaluated many times per commit, everything it creates
is created with `idempotent: true`: the first evaluation creates the job run,
and every later evaluation gets back that same job run and its current status.

Inside the container the environment contains:

| Variable | Contents |
| --- | --- |
| `WORKFLOW_RUN_ID` | The id of the workflow run being evaluated |
| `SATURNCI_ACCESS_TOKEN` | An API token scoped to this evaluation |
| `BRANCH_NAME`, `COMMIT_HASH`, `COMMIT_MESSAGE`, `AUTHOR_NAME` | The commit's git metadata |

## A minimal workflow

This workflow clones the repository, runs the test suite, and finishes.

```ruby
# .saturnci/workflows/default_workflow.rb

class DefaultWorkflow
  def initialize(env: ENV)
    @env = env
  end

  def perform(io: $stdout)
    clone_repo_job_run = workflow_run.job_runs.create(
      job_name: 'clone_repo',
      task_adapter_name: 'shell',
      idempotent: true
    )
    clone_repo_job_run.start
    return unless clone_repo_job_run.passed?

    test_suite_run = workflow_run.test_suite_runs.create(
      job_name: 'test_suite',
      task_adapter_name: 'rspec',
      idempotent: true
    )
    test_suite_run.start
    io.puts "Test suite: #{test_suite_run.url}"

    test_suite_run = SaturnCI::TestSuiteRun.find(client: client, id: test_suite_run.id)
    finish(io) if test_suite_run.passed? || test_suite_run.failed?
  end

  def finish(io)
    workflow_run.finish
    io.puts 'Workflow finished.'
  end

  def workflow_run
    @workflow_run ||= SaturnCI::WorkflowRun.find(client: client, id: @env.fetch('WORKFLOW_RUN_ID'))
  end

  def client
    SaturnCI::Client.new(SaturnCI::Credentials.new(api_token: @env.fetch('SATURNCI_ACCESS_TOKEN')))
  end
end

DefaultWorkflow.new.perform if $PROGRAM_NAME == __FILE__
```

Read it as a sequence of evaluations:

1. **On push:** the `clone_repo` job run is created and started. It hasn't
   passed yet, so the file returns.
2. **When `clone_repo` finishes:** `create` returns the existing job run, now
   passed. The test suite run is created and started; it isn't finished yet,
   so the file returns.
3. **When the test suite finishes:** both runs already exist; the test suite
   run has passed or failed, so the workflow run is finished.

`clone_repo` and `test_suite` are jobs defined in your repository under
`.saturnci/jobs/`. See [Jobs](https://www.saturnci.com/jobs.html) for how to
define one and [Environments](https://www.saturnci.com/environments.html) for
the containers they run in.

## Building on the minimal workflow

### Only on `main`

```ruby
return unless workflow_run.branch_name == 'main'
```

### Running jobs in parallel

Create and start several job runs in the same evaluation; they run
concurrently. Later evaluations check each one.

```ruby
rubocop_job_run = workflow_run.job_runs.create(job_name: 'rubocop', task_adapter_name: 'shell', idempotent: true)
rubocop_job_run.start

javascript_job_run = workflow_run.job_runs.create(job_name: 'javascript', task_adapter_name: 'shell', idempotent: true)
javascript_job_run.start
```

### Looking up a run created in an earlier evaluation

```ruby
test_suite_run = workflow_run.job_runs.list(job_name: 'test_suite').first
return unless test_suite_run&.passed?
```

`list` returns `[]` when nothing with that name has been created yet.

### Passing values to a job

Extra keyword arguments to `create` become the job's params, and reach the
job's container as upper-cased environment variables.

```ruby
deploy_job_run = workflow_run.job_runs.create(
  job_name: 'deploy',
  task_adapter_name: 'shell',
  container_image_url: 'registry.example.com/app:abc123',
  idempotent: true
)
# The deploy job sees CONTAINER_IMAGE_URL=registry.example.com/app:abc123
```

Params set after creation:

```ruby
deploy_job_run.update(container_image_url: image_url)
```

### Passing values between jobs

A job can read another job's params:

```ruby
production_image_build_job_run = workflow_run.job_runs.list(job_name: 'production_image_build').find(&:passed?)
image_url = SaturnCI::JobRun.find(client: client, id: production_image_build_job_run.id).params['container_image_url']
```

### Linking a run to a parent

Pass `parent_job_run_id:` to `create` to show a run nested under another in
the SaturnCI UI.

## Reference

### `SaturnCI::Client` and `SaturnCI::Credentials`

```ruby
client = SaturnCI::Client.new(SaturnCI::Credentials.new(api_token: token))
```

`SaturnCI::Credentials.new` with no arguments reads the token from
`~/.saturnci/credentials.json` (see
[API Authentication](https://www.saturnci.com/api-authentication.html)).

The API host defaults to `https://app.saturnci.com` and can be overridden with
the `SATURNCI_API_HOST` environment variable or `base_url:`.

`client.authenticated?` returns whether the token is accepted. Requests the
API rejects raise `SaturnCI::InvalidRequestError`.

### `SaturnCI::WorkflowRun`

| | |
| --- | --- |
| `WorkflowRun.find(client:, id:)` | Fetch a workflow run |
| `id`, `branch_name`, `commit_hash`, `commit_message`, `author_name`, `repository_full_name` | The run and its commit |
| `job_runs.create(job_name:, task_adapter_name:, idempotent: true, **params)` | Create a job run in this workflow run |
| `job_runs.list(job_name:)` | The job runs with that name in this workflow run |
| `test_suite_runs.create(job_name:, task_adapter_name:, idempotent: true, **params)` | Create a test suite run in this workflow run |
| `finish` | Mark the workflow run finished |

Runs created through `job_runs` and `test_suite_runs` inherit the workflow
run's repository and commit.

### `SaturnCI::JobRun`

| | |
| --- | --- |
| `JobRun.find(client:, id:)` | Fetch a job run, including its `params` |
| `JobRun.list(client:, job_name:, status: nil, workflow_run_id: nil)` | List job runs |
| `JobRun.create(client:, repository:, job_name:, **params)` | Create a job run outside a workflow |
| `start` | Start it (`create` does not) |
| `update(**params)` | Change its params |
| `passed?`, `failed?` | Its outcome |
| `status` | One of `:not_started`, `:queued`, `:running`, `:passed`, `:failed`, `:cancelled`, `:timed_out` |
| `id`, `url`, `job_name`, `branch_name`, `params`, `parent_job_run_id` | Attributes |
| `wait_for_completion` | Block until the run reaches a final status (for scripts, not workflows) |

`task_adapter_name` for job runs is `shell`.

### `SaturnCI::TestSuiteRun`

| | |
| --- | --- |
| `TestSuiteRun.find(client:, id:)` | Fetch a test suite run |
| `TestSuiteRun.list(client:, commit_hash:)` | List test suite runs for a commit |
| `TestSuiteRun.create(client:, repository:, **params)` | Create a test suite run outside a workflow |
| `start` | Start it (`create` does not) |
| `passed?`, `failed?`, `status` | As for job runs |
| `id`, `url`, `parent_job_run_id` | Attributes |
| `wait_for_completion` | Block until the run reaches a final status |

`task_adapter_name` for test suite runs is one of `rails_rspec`, `rspec`,
`minitest`, or `rails_minitest`. `task_adapter_version:` selects an adapter
version where more than one exists. `command:` overrides the command the
adapter runs, e.g. `'bundle exec appraisal rails-7.1 rspec'`.

## Using the SDK outside a workflow

Inside a workflow the gem is already installed. To use it from your own
machine or scripts, install it from its repository at a tagged release:

```ruby
gem 'saturnci-sdk', git: 'https://github.com/saturnci/saturnci-sdk.git', tag: 'v1.0.1'
```

Requires Ruby 3.0 or later. With credentials in
`~/.saturnci/credentials.json`:

```ruby
require 'saturnci-sdk'

client = SaturnCI::Client.new

test_suite_run = SaturnCI::TestSuiteRun.create(
  client: client,
  repository: 'your-org/your-repo',
  job_name: 'test_suite',
  branch_name: 'main',
  commit_hash: `git rev-parse HEAD`.strip,
  commit_message: `git log -1 --format=%s`.strip,
  author_name: `git log -1 --format=%an`.strip,
  task_adapter_name: 'rails_rspec'
)
test_suite_run.start

puts test_suite_run.url
test_suite_run.wait_for_completion
puts test_suite_run.status
```

## License

MIT
