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

```ruby
require 'alephant/broker'
require 'alephant/broker/load_strategy/s3'

config = {
  :s3_bucket_id      => 'test_bucket',
  :s3_object_path    => 'foo',
  :lookup_table_name => 'test_lookup'
}

request = {
  'PATH_INFO'      => '/component/foo',
  'QUERY_STRING'   => 'variant=bar',
  'REQUEST_METHOD' => 'GET'
}

Alephant::Broker::Application.new(
  Alephant::Broker::LoadStrategy::S3.new,
  config
).call(request).tap do |response|
  puts "status:  #{response.status}"
  puts "content: #{response.content}"
end
```

##### HTML Load Strategy

```ruby
require 'alephant/broker'
require 'alephant/broker/load_strategy/http'

class UrlGenerator < Alephant::Broker::LoadStrategy::HTTP::URL
  def generate(id, options)
    "http://example-api.com/data?id=#{id}"
  end
end

request = {
  'PATH_INFO'      => '/component/foo',
  'QUERY_STRING'   => 'variant=bar',
  'REQUEST_METHOD' => 'GET'
}

Alephant::Broker::Application.new(
  Alephant::Broker::LoadStrategy::HTTP.new(UrlGenerator.new),
  {}
).call(request).tap do |response|
  puts "status:  #{response.status}"
  puts "content: #{response.content}"
end
```

**Note**

The HTML load strategy relies upon being given a URLGenerator, which is used to generate the URL of the HTML endpoint (see below for example). The class must:

* be implemented within your own application.
* extend [`Alephant::Broker::LoadStrategy::HTTP::URL`](https://github.com/BBC-News/alephant-broker/blob/master/lib/alephant/broker/load_strategy/http.rb#L9-L13).
* include a `#generate` method which takes `id` (string) and `options` (hash) as parameters.

```ruby
require 'alephant/broker/load_strategy/http'
require 'rack'

class UrlGenerator < Alephant::Broker::LoadStrategy::HTTP::URL
  def generate(id, options)
    "http://api.my-app.com/component/#{id}?#{to_query_string(options)}"
  end

  private

  def to_query_string(hash)
    Rack::Utils.build_query hash
  end
end
```

### Rack App

Create **config.ru** using example below, and then run:

    rackup config.ru

```ruby
require 'alephant/broker'
require 'alephant/broker/load_strategy/http'

class UrlGenerator < Alephant::Broker::LoadStrategy::HTTP::URL
  def generate(id, options)
    "http://example-api.com/data?id=#{id}"
  end
end

run Alephant::Broker::Application.new(
  Alephant::Broker::LoadStrategy::HTTP.new(UrlGenerator.new),
  {}
)
```

### Cache version number

The broker looks for a configuration value `elasticache_cache_version` and if it exists it uses it to construct the cache key.
This allows the cache to be busted if the data in the cache changes, or for any other reason that it needs to be invalidated.

This version is added as a header to the response in the following format:

`X-Cache-Version: {CACHE_VERSION}`


## Contributing

1. [Fork it!]( http://github.com/bbc-news/alephant-broker/fork)
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new [Pull Request](https://github.com/BBC-News/alephant-broker/pulls).

Feel free to create a new [issue](https://github.com/BBC-News/alephant-broker/issues/new) if you find a bug.



