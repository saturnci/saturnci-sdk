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

client = SaturnCI::Client.new(user_id: 'your_user_id', api_token: 'your_api_token')
client.authenticated?
```

Credentials can be found in `~/.saturnci/credentials.json`.
