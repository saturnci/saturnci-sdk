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

Credentials are read automatically from `~/.saturnci/credentials.json`. You can also pass them explicitly:

```ruby
credentials = SaturnCI::Credentials.new(user_id: 'your_user_id', api_token: 'your_api_token')
client = SaturnCI::Client.new(credentials)
```

### Triggering a deploy

```ruby
client = SaturnCI::Client.new

job = SaturnCI::Job.create(
  client: client,
  repository: 'your-org/your-repo',
  name: 'deploy',
  container_image_url: 'your-registry/your-image:tag'
)

puts "Job created: #{job.id}"
```
