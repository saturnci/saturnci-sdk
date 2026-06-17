# saturnci-sdk

Ruby SDK for the [SaturnCI](https://www.saturnci.com/) API.

With SaturnCI you define your CI/CD pipeline in Ruby rather than YAML. This gem
gives you the building blocks: trigger test suite runs, build container images,
run jobs, and wait for their results.

## Installation

```
gem install saturnci-sdk
```

Or add it to your Gemfile:

```ruby
gem 'saturnci-sdk'
```

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

```ruby
github_accounts = SaturnCI::GitHubAccount.list(client: client)
github_accounts.each(&:destroy)
```

Revoke the GitHub OAuth grant for the authenticated user:

```ruby
SaturnCI::GitHubOAuthGrant.destroy(client: client)
```

## A complete pipeline: test, build, and deploy

```ruby
client = SaturnCI::Client.new
repository = 'your-org/your-repo'

# Test
test_suite_run = SaturnCI::TestSuiteRun.create(
  client: client,
  repository: repository,
  branch_name: `git rev-parse --abbrev-ref HEAD`.strip,
  commit_hash: `git rev-parse HEAD`.strip,
  commit_message: `git log -1 --format=%s`.strip,
  author_name: `git log -1 --format=%an`.strip,
  task_adapter_name: 'rails_rspec'
)
puts "Testing: #{test_suite_run.url}"
test_suite_run.wait_for_completion
abort 'Tests failed!' unless test_suite_run.status == 'Passed'

# Build
container_image_build = SaturnCI::ContainerImageBuild.create(
  client: client,
  repository: repository,
  name: 'production'
)
puts "Building: #{container_image_build.url}"
container_image_build.wait_for_completion

# Deploy
job_run = SaturnCI::JobRun.create(
  client: client,
  repository: repository,
  job_name: 'deploy',
  container_image_url: container_image_build.container_image_url
)
puts "Deploying: #{job_run.url}"
job_run.wait_for_completion
puts "Deploy complete!"
```

## License

MIT
