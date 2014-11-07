# Alephant::Broker

Brokers requests for rendered templates, retrieved from S3 or a HTML endpoint.

[![Build Status](https://travis-ci.org/BBC-News/alephant-broker.png?branch=master)](https://travis-ci.org/BBC-News/alephant-broker)[![Gem Version](https://badge.fury.io/rb/alephant-broker.png)](http://badge.fury.io/rb/alephant-broker)

## Installation

Add this line to your application's Gemfile:

    gem 'alephant-broker'

And then execute:

    bundle install

Or install it yourself as:

    gem install alephant-broker

## Usage

The **Broker** is capable of retrieving rendered templates from either [S3](http://aws.amazon.com/s3/) or a HTML endpoint (e.g. [alephant-publisher-request](https://github.com/BBC-News/alephant-publisher-request)). This must be decided when creating an instance of the **Broker**, as a **load strategy** is given as a parameter (see below for examples).

### Barebones

##### S3 Load Strategy

```
require 'alephant/broker'
require 'alephant/broker/load_strategy/s3'

config = {
  :bucket_id         => 'test_bucket',
  :path              => 'foo',
  :lookup_table_name => 'test_lookup'
}

request = {
  'PATH_INFO'      => '/component/foo'
  'QUERY_STRING'   => 'variant=bar',
  'REQUEST_METHOD' => 'GET'
}

Alephant::Broker::Application.new(
  Alephant::Broker::LoadStrategy::S3.new,
  config
).call(request).tap do |response|
  puts "status:  #{response.code}"
  puts "content: #{response.content}"
end
```

##### HTML Load Strategy

```
require 'alephant/broker'
require 'alephant/broker/load_strategy/http'

class UrlGenerator < Alephant::Broker::LoadStrategy::HTTP::URL
  def generate
    'http://example-api.com/data'
  end
end

request = {
  'PATH_INFO'      => '/component/foo'
  'QUERY_STRING'   => 'variant=bar',
  'REQUEST_METHOD' => 'GET'
}

Alephant::Broker::Application.new(
  Alephant::Broker::LoadStrategy::HTML.new(URLGenerator.new)
).call(request).tap do |response|
  puts "status:  #{response.code}"
  puts "content: #{response.content}"
end
```

### Rack App

Create **config.ru** using example below, and then run:

    rackup config.ru

```
require 'alephant/broker'
require 'alephant/broker/load_strategy/http'

class UrlGenerator < Alephant::Broker::LoadStrategy::HTTP::URL
  def generate
    'http://example-api.com/data'
  end
end

run Alephant::Broker::Application.new(
  Alephant::Broker::LoadStrategy::HTTP.new(UrlGenerator.new),
  {}
)

```

## Contributing

1. [Fork it!]( http://github.com/bbc-news/alephant-broker/fork)
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new [Pull Request](https://github.com/BBC-News/alephant-broker/pulls).

Feel free to create a new [issue](https://github.com/BBC-News/alephant-broker/issues/new) if you find a bug.



