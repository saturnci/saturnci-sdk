# saturnci-sdk

Ruby SDK for the [SaturnCI](https://www.saturnci.com/) API.

With SaturnCI you define your CI/CD pipeline in Ruby rather than YAML. This gem
gives you the building blocks: trigger test suite runs, build container images,
run jobs, and wait for their results.

## Installation

The gem is installed from its git repository. Add it to your Gemfile, pinned to
a specific ref:

```ruby
gem 'saturnci-sdk', git: 'https://github.com/saturnci/saturnci-sdk.git', ref: 'fd22a7e'
```

Then run `bundle install`.

Requires Ruby 3.0 or later.

## Authentication

Create a client. By default it reads credentials from
`~/.saturnci/credentials.json` (see
[API Authentication](https://www.saturnci.com/api-authentication.html) for setup
instructions).

```ruby
require 'saturnci-sdk'

client = SaturnCI::Client.new
client.authenticated? # => true
```

You can also pass credentials explicitly:

```ruby
credentials = SaturnCI::Credentials.new(api_token: 'your_api_token')
client = SaturnCI::Client.new(credentials)
```

The API host defaults to `https://app.saturnci.com` and can be overridden with
the `SATURNCI_API_HOST` environment variable.

Requests that the API rejects raise `SaturnCI::InvalidRequestError`.

## Test suite runs

### Creating a test suite run

```ruby
client = SaturnCI::Client.new

test_suite_run = SaturnCI::TestSuiteRun.create(
  client: client,
  repository: 'your-org/your-repo',
  branch_name: 'main',
  commit_hash: `git rev-parse HEAD`.strip,
  commit_message: `git log -1 --format=%s`.strip,
  author_name: `git log -1 --format=%an`.strip,
  task_adapter_name: 'rails_rspec'
)

puts "Testing: #{test_suite_run.url}"
test_suite_run.wait_for_completion
puts "Status: #{test_suite_run.status}"
```

`wait_for_completion` blocks until the run reaches a terminal status (`Passed`,
`Failed`, `Cancelled`, or `Timed Out`) and sets `status`.

Valid `task_adapter_name` values: `shell`, `rails_rspec`, `rspec`, `minitest`,
`rails_minitest`, `container_image_build`.

These additional parameters are optional:

- `command` — overrides the default command the adapter runs, e.g.
  `'bundle exec appraisal rails-7.1 rspec'`.
- `parent_job_run_id` — links the run to a parent job run (see below).

### Running a test suite run as part of a job

When a test suite run is created from within a job, pass `parent_job_run_id` to
link the two. The created run exposes that id via `parent_job_run_id`.

```ruby
test_suite_run = SaturnCI::TestSuiteRun.create(
  client: client,
  repository: 'your-org/your-repo',
  branch_name: 'main',
  commit_hash: `git rev-parse HEAD`.strip,
  commit_message: `git log -1 --format=%s`.strip,
  author_name: `git log -1 --format=%an`.strip,
  task_adapter_name: 'rails_rspec',
  parent_job_run_id: ENV.fetch('JOB_RUN_ID')
)

puts "Parent job run: #{test_suite_run.parent_job_run_id}"
```

### Listing test suite runs

```ruby
test_suite_runs = SaturnCI::TestSuiteRun.list(
  client: client,
  commit_hash: `git rev-parse HEAD`.strip
)

test_suite_runs.each do |test_suite_run|
  puts test_suite_run.id
end
```

Listed runs carry their `id`. Fetch a run's status with `wait_for_completion`.

## Container image builds

```ruby
container_image_build = SaturnCI::ContainerImageBuild.create(
  client: client,
  repository: 'your-org/your-repo',
  name: 'production'
)

puts "Building: #{container_image_build.url}"
container_image_build.wait_for_completion
puts "Image: #{container_image_build.container_image_url}"
```

`wait_for_completion` blocks until the build reaches a terminal status and sets
`container_image_url`.

## Job runs

A job must be [defined](https://www.saturnci.com/jobs.html) before it can be run.

### Creating a job run

```ruby
job_run = SaturnCI::JobRun.create(
  client: client,
  repository: 'your-org/your-repo',
  job_name: 'deploy',
  container_image_url: 'your-registry/your-image:tag'
)

puts "Running: #{job_run.url}"
job_run.wait_for_completion
puts "Status: #{job_run.status}"
```

### Listing job runs

```ruby
job_runs = SaturnCI::JobRun.list(
  client: client,
  job_name: 'deploy',
  status: 'Passed'
)

job_runs.each do |job_run|
  puts job_run.id
end
```

`status` is optional; omit it to list job runs of any status. Listed job runs
carry their `id`.

## GitHub accounts

List the GitHub accounts connected to the authenticated user:

```ruby
github_accounts = SaturnCI::GitHubAccount.list(client: client)

github_accounts.each do |github_account|
  puts github_account.id
end
```

## A complete pipeline: test and deploy

This is the entrypoint SaturnCI uses to test and deploy itself. On a push, it
runs the test suite and, if the tests pass on `main`, runs the deploy job. The
test suite run and the deploy job run are both linked to the entrypoint job run
via `parent_job_run_id`.

```ruby
#!/usr/bin/env ruby

class EntrypointJob
  def initialize(io:, error_io:, github_event:, client:)
    @io = io
    @error_io = error_io
    @github_event = github_event
    @client = client
  end

  def perform
    @io.puts "SaturnCI SDK version: #{SaturnCI::VERSION}"

    return 0 unless @github_event == "push"
    return 0 if ENV['DELETED'] == "true"

    return 1 unless assert_env_presence(
      "BRANCH_NAME",
      "COMMIT_HASH",
      "COMMIT_MESSAGE",
      "AUTHOR_NAME"
    )

    test_suite_run = SaturnCI::TestSuiteRun.create(
      client: @client,
      repository: 'your-org/your-repo',
      job_name: 'test_suite',
      task_adapter_name: 'rails_rspec',
      parent_job_run_id: ENV['JOB_RUN_ID'],
      branch_name: ENV['BRANCH_NAME'],
      commit_hash: ENV['COMMIT_HASH'],
      commit_message: ENV['COMMIT_MESSAGE'],
      author_name: ENV['AUTHOR_NAME']
    )

    @io.puts "Testing: #{test_suite_run.url}"
    test_suite_run.wait_for_completion
    @io.puts "Tests #{test_suite_run.status.downcase}."

    if test_suite_run.status == "Passed" && ENV['BRANCH_NAME'] == "main"
      @io.puts "Starting deploy"
      deploy_job_run = SaturnCI::JobRun.create(
        client: @client,
        repository: 'your-org/your-repo',
        job_name: 'deploy',
        name: ENV['COMMIT_MESSAGE'],
        branch_name: ENV['BRANCH_NAME'],
        commit_hash: ENV['COMMIT_HASH'],
        commit_message: ENV['COMMIT_MESSAGE'],
        author_name: ENV['AUTHOR_NAME'],
        parent_job_run_id: test_suite_run.id
      )

      deploy_job_run.wait_for_completion
      @io.puts "Deploy #{deploy_job_run.status.downcase}"
    end

    0
  end

  private

  def assert_env_presence(*names)
    names.each do |name|
      if ENV[name].to_s.empty?
        @error_io.puts "#{name} env var is required"
        return false
      end
    end
    true
  end
end

def client
  SaturnCI::Client.new(SaturnCI::Credentials.new(api_token: ENV.fetch('SATURNCI_ACCESS_TOKEN')))
end

if $PROGRAM_NAME == __FILE__
  exit EntrypointJob.new(
    io: $stdout,
    error_io: $stderr,
    github_event: ENV['GITHUB_EVENT'],
    client: client
  ).perform
end
```

## License

MIT
