# saturnci-sdk

Ruby SDK for the SaturnCI API.

## Installation

```
gem install saturnci-sdk
```

Or add to your Gemfile:

```ruby
gem 'saturnci-sdk'
```

## Usage

```ruby
require 'saturnci-sdk'

client = SaturnCI::Client.new
client.authenticated?
```

Credentials are read automatically from `~/.saturnci/credentials.json` (see [API Authentication](https://www.saturnci.com/api-authentication.html) for setup instructions). You can also pass them explicitly:

```ruby
credentials = SaturnCI::Credentials.new(user_id: 'your_user_id', api_token: 'your_api_token')
client = SaturnCI::Client.new(credentials)
```

### Running tests

```ruby
client = SaturnCI::Client.new

test_suite_run = SaturnCI::TestSuiteRun.create(
  client: client,
  repository: 'your-org/your-repo',
  branch_name: 'main',
  commit_hash: `git rev-parse HEAD`.strip,
  commit_message: `git log -1 --format=%s`.strip,
  author_name: `git log -1 --format=%an`.strip
)

puts "Testing: #{test_suite_run.url}"
test_suite_run.wait_for_completion
puts "Status: #{test_suite_run.status}"
```

### Building a Docker image

```ruby
client = SaturnCI::Client.new

build = SaturnCI::Build.create(
  client: client,
  repository: 'your-org/your-repo',
  name: 'production'
)

puts "Building: #{build.url}"
build.wait_for_completion
puts "Image: #{build.container_image_url}"
```

### Running a job

A job must be [defined](https://www.saturnci.com/jobs.html) before it can be created.

```ruby
client = SaturnCI::Client.new

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

### Test, build, and deploy

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
  author_name: `git log -1 --format=%an`.strip
)
puts "Testing: #{test_suite_run.url}"
test_suite_run.wait_for_completion
abort "Tests failed!" unless test_suite_run.status == "Passed"

# Build
build = SaturnCI::Build.create(client: client, repository: repository, name: 'production')
puts "Building: #{build.url}"
build.wait_for_completion
puts "Image: #{build.container_image_url}"

# Deploy
job_run = SaturnCI::JobRun.create(client: client, repository: repository, job_name: 'deploy', container_image_url: build.container_image_url)
puts "Deploying: #{job_run.url}"
job_run.wait_for_completion
puts "Deploy complete!"
```
