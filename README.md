# Theoldreader::Api

Ruby wrapper for [Theoldreader's API](https://github.com/theoldreader/api).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'theoldreader-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install theoldreader-api

## Usage

### Authentication
First you need to [obtain a token](https://github.com/theoldreader/api#authentication) for theoldreader user:

```ruby

require 'theoldreader-api'

Theoldreader::Api.new.accounts_clientlogin(
  Email: 'test@krasnoukhov.com', Passwd: '...', client: 'YourAppName'
)
=> {"SID"=>"none", "LSID"=>"none", "Auth"=>"LyTEJPvTJiSPrCxLu46d"}
```

With this token you have access to all other methods of Theoldreader's API.

### Generic

```ruby
api = Theoldreader::Api.new("LyTEJPvTJiSPrCxLu46d")

api.call!('get', '/reader/api/0/user-info', {output: 'json'})
```

`call!` will pass every option you provide directly to Theoldreader's Api.

### Shortcut

```ruby
api.call('user-info')

api.call('subscription/quickadd', quickadd: 'http://xkcd.com')

api.call('tag/list')

api.call('/reader/subscriptions/export')

```

`call` will filter your options to include only those listed in specification for the given endpoint.

`call` accepts endpoints from `Theoldreader::Api::ENDPOINTS.keys` as its first 

`Theoldreader::Api::ENDPOINTS` includes all available methods from Theoldreader's API (with 'reader/api/0/' being left out), except those three wich returns specific atom feeds (https://theoldreader.com/reader/atom/...). You can access them if you want with `call!`

### Shortcuts for shortcuts

If you mentally process your endpoint through `.downcase.sub(%r{^/+}, '').gsub(%r{[-/]}, '_')` you should also get available method for Api.

```ruby
# to get userinfo
api.user_info

# to add new feed
api.subscription_quickadd(quickadd: 'http://xkcd.com')

# to get the last two unread items
api.stream_contents(
  s: 'user/-/state/com.google/reading-list',
  xt: 'user/-/state/com.google/read',
  n: 2
)
```

Works only for keys listed in `Theoldreader::Api::ENDPOINTS.keys`

## Advanced Usage

You can change [faraday](https://github.com/lostisland/faraday) adapter:

```ruby
require 'net/http/persistent'

Theoldreader::Api.new('LyTEJPvTJiSPrCxLu46d', {adapter: :net_http_persistent})
```

And you can use API via http instead of https:

```ruby
Theoldreader::Api.new('LyTEJPvTJiSPrCxLu46d', {use_ssl: false})
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ilzoff/theoldreader-api.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

