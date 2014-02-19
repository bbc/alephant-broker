# Alephant::Broker

Brokers requests for alephant components

## Installation

Add this line to your application's Gemfile:

    gem 'alephant-broker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install alephant-broker

## Usage

### Barebones

```ruby
require 'alephant/broker'

request = Alephant::Broker::Request.new('/component/id', 'variant=hello')
config  = {
  :bucket_id         => "s3-render-example",
  :path              => "foo",
  :lookup_table_name => "example_lookup"
}

broker = Alephant::Broker.handle(request, config)

# => #<Alephant::Broker::Response:0x5215005d
# @content="<p>some HTML response</p>",
# @content_type="text/html",
# @status=200>
```

### Simple App

```ruby
require 'alephant/broker/app'

config  = {
  :bucket_id         => "s3-render-example",
  :path              => "foo",
  :lookup_table_name => "example_lookup"
}

app = Alephant::Broker::Application.new(config)
request = app.request_from('/component/id', 'variant=hello')

app.handle(request)

# => #<Alephant::Broker::Response:0x5215005d
# @content="<p>some HTML response</p>",
# @content_type="text/html",
# @status=200>
```

### Rack

```ruby
require 'alephant/broker/app/rack'
require 'configuration'

module Foo
  class Bar < Alephant::Broker::RackApplication
    def initialize
      super(Configuration.new)
    end
  end
end
```

## Pry'ing

If you're using Pry to debug this gem...

```ruby
export AWS_ACCESS_KEY_ID='xxxx'
export AWS_SECRET_ACCESS_KEY='xxxx'
export AWS_REGION='eu-west-1'

config = {
  :bucket_id         => "s3-render-example",
  :path              => "foo",
  :lookup_table_name => "example_lookup"
}
 
env = {
  "PATH_INFO"    => "/component/england_council_header",
  "QUERY_STRING" => ""
}
 
require 'alephant/broker/app/rack'
 
app = Alephant::Broker::RackApplication.new(config)
app.call(env)
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/alephant-broker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
