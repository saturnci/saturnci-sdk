# saturnci-sdk

Ruby SDK for the SaturnCI API.

## Why does this SDK exist?

How does one define a pipeline in GitHub Actions, CircleCI or GitLab? YAML, of course.

```yaml
- name: Keep screenshots from failed system tests
  uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: screenshots
    path: ${{ github.workspace }}/tmp/capybara
    if-no-files-found: ignore
```

How did we get here? How did we get to a place where we're using a configuration file format as a programming language?

No one sat down one day and decided that large, complex, mission-critical software systems built in executable YAML would be a good idea. (If they did, they should be punished.) Presumably, we have YAML-as-code because a succession of locally reasonable decisions accumulated over time to create a monstrosity.

I invite you to take a leisurely scroll through this [RSpec/Rails GitHub Actions configuration example](https://thoughtbot.com/blog/rspec-rails-github-actions-configuration) I found.

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - name: Install packages
        run: sudo apt-get update && sudo apt-get install --no-install-recommends -y google-chrome-stable curl libjemalloc2 libvips postgresql-client libpq-dev

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true

      - name: Run tests
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432
        run: bin/rails db:setup spec

      - name: Keep screenshots from failed system tests
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: screenshots
          path: ${{ github.workspace }}/tmp/capybara
          if-no-files-found: ignore
```

I happen to think this is madness. There's a better way to define CI pipelines. We don't even have to invent any new tools. There's something that's been right under our noses the whole time.

## An alternative to executable YAML

Pipelines are software systems. Often times, pipelines are complex, mission-critical software systems. Software systems benefit from having the following qualities:

**Testability.** Do you ever commit a change and then deploy it to production without testing it, not even by pulling it up in the browser? Of course not. That would be foolishly, shamefully reckless. No responsible programmer would work that way. Yet, that's the _default_ workflow for maintaining pipelines. Just commit the change and hope it works. No thank you!

**Universality.** A programming language is _universal_ (or Turing complete if you like) if anything that can be computed can be computed using the language. Ruby, Python, Java, C, etc. all possess this property of universality. Hacks have been added on top of YAML to try to make it universal, and these hacks "work", but why not just use a language that already has universality built in?

[SaturnCI](https://www.saturnci.com/) doesn't use executable YAML to define pipelines. It uses a programming language. Specifically, it uses Ruby. Below is an example of how a SaturnCI pipeline is defined.

```ruby
#!/usr/bin/env ruby

def run(io, error_io, github_event, client)
  io.puts "SaturnCI SDK version: #{SaturnCI::VERSION}"

  return 0 unless github_event == "push"
  return 0 if ENV['DELETED'] == "true"

  branch_name = ENV['BRANCH_NAME']
  if branch_name.to_s.empty?
    error_io.puts "BRANCH_NAME env var is required"
    return 1
  end

  commit_hash = ENV['COMMIT_HASH']
  if commit_hash.to_s.empty?
    error_io.puts "COMMIT_HASH env var is required"
    return 1
  end

  commit_message = ENV['COMMIT_MESSAGE']
  author_name = ENV['AUTHOR_NAME']

  io.puts "Branch name: #{branch_name}"
  io.puts "Commit hash: #{commit_hash}"
  io.puts "Commit message: #{commit_message}"
  io.puts "Author name: #{author_name}"

  test_suite_run = SaturnCI::TestSuiteRun.create(
    client: client,
    repository: 'saturnci/saturnci',
    branch_name: branch_name,
    commit_hash: commit_hash,
    commit_message: commit_message,
    author_name: author_name,
    task_adapter_name: 'rails_rspec'
  )

  io.puts "Testing: #{test_suite_run.url}"
  test_suite_run.wait_for_completion
  io.puts "Tests #{test_suite_run.status.downcase}."

  if test_suite_run.status == "Passed" && branch_name == "main"
    io.puts "Starting deploy"
    deploy_job_run = SaturnCI::JobRun.create(
      client: client,
      repository: 'saturnci/saturnci',
      job_name: 'deploy',
      name: commit_message,
      branch_name: branch_name,
      commit_hash: commit_hash,
      commit_message: commit_message,
      author_name: author_name
    )

    deploy_job_run.wait_for_completion
    io.puts "Deploy #{deploy_job_run.status.downcase}"
  end

  0
end

def client
  SaturnCI::Client.new(credentials)
end

def credentials
  SaturnCI::Credentials.new(
    api_token: ENV.fetch('SATURNCI_API_TOKEN')
  )
end

exit run($stdout, $stderr, ENV['GITHUB_EVENT'], client) if $PROGRAM_NAME == __FILE__
```

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
credentials = SaturnCI::Credentials.new(api_token: 'your_api_token')
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
  author_name: `git log -1 --format=%an`.strip,
  task_adapter_name: 'rails_rspec'
)

puts "Testing: #{test_suite_run.url}"
test_suite_run.wait_for_completion
puts "Status: #{test_suite_run.status}"
```

Valid `task_adapter_name` values: `shell`, `rails_rspec`, `rspec`, `minitest`, `rails_minitest`, `container_image_build`.

### Building a Docker image

```ruby
client = SaturnCI::Client.new

container_image_build = SaturnCI::ContainerImageBuild.create(
  client: client,
  repository: 'your-org/your-repo',
  name: 'production'
)

puts "Building: #{container_image_build.url}"
container_image_build.wait_for_completion
puts "Image: #{container_image_build.container_image_url}"
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
  author_name: `git log -1 --format=%an`.strip,
  task_adapter_name: 'rails_rspec'
)
puts "Testing: #{test_suite_run.url}"
test_suite_run.wait_for_completion
abort "Tests failed!" unless test_suite_run.status == "Passed"

# Build
container_image_build = SaturnCI::ContainerImageBuild.create(client: client, repository: repository, name: 'production')
puts "Building: #{container_image_build.url}"
container_image_build.wait_for_completion
puts "Image: #{container_image_build.container_image_url}"

# Deploy
job_run = SaturnCI::JobRun.create(client: client, repository: repository, job_name: 'deploy', container_image_url: container_image_build.container_image_url)
puts "Deploying: #{job_run.url}"
job_run.wait_for_completion
puts "Deploy complete!"
```
