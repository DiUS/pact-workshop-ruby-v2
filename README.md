Example Ruby Project for Pact Workshop
======================================

When writing a lot of small services, testing the interactions between these becomes a major headache. That's the problem Pact is trying to solve.

Integration tests typically are slow and brittle, requiring each component to have it's own environment to run the tests in. With a micro-service architecture, this becomes even more of a problem. They also have to be 'all-knowing' and this makes them difficult to keep from being fragile.

After J. B. Rainsberger's talk "Integrated Tests Are A Scam" people have been thinking how to get the confidence we need to deploy our software to production without having a tiresome integration test suite that does not give us all the coverage we think it does.

Pact is a ruby gem that allows you to define a pact between service consumers and providers. It provides a DSL for service consumers to define the request they will make to a service producer and the response they expect back. This expectation is used in the consumers specs to provide a mock producer, and is also played back in the producer specs to ensure the producer actually does provide the response the consumer expects.

This allows you to test both sides of an integration point using fast unit tests.

## Step 1 - Simple Consumer calling Provider

Given we have a client that needs to make a HTTP GET request to a sinatra webapp, and requires a response in JSON format. The client would look something like:

client.rb:

```ruby
    require 'httparty'
    require 'uri'
    require 'json'

    class Client


      def load_provider_json
        response = HTTParty.get(URI::encode('http://localhost:8081/provider.json?valid_date=' + Time.now.httpdate))
        if response.success?
          JSON.parse(response.body)
        end
      end


    end
```

and the provider:
provider.rb

```ruby
    require 'sinatra/base'
    require 'json'


    class Provider < Sinatra::Base


      get '/provider.json', :provides => 'json' do
        valid_time = Time.parse(params[:valid_date])
        JSON.pretty_generate({
          :test => 'NO',
          :valid_date => DateTime.now,
          :count => 1000
        })
      end

    end
```

This provider expects a valid_date parameter in HTTP date format, and then returns some simple json back.

Running the client with the following rake task against the provider works nicely:

```ruby
    desc 'Run the client'
    task :run_client => :init do
      require 'client'
      require 'ap'
      ap Client.new.load_provider_json
    end
```

    $ rake run_client
    {
              "test" => "NO",
        "valid_date" => "2016-03-20T13:00:11+11:00",
             "count" => 1000
    }
