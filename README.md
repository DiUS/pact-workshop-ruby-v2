Example Ruby Project for Pact Workshop
======================================

When writing a lot of small services, testing the interactions between these becomes a major headache. That's the problem Pact is trying to solve.

Integration tests typically are slow and brittle, requiring each component to have it's own environment to run the tests in. With a micro-service architecture, this becomes even more of a problem. They also have to be 'all-knowing' and this makes them difficult to keep from being fragile.

After J. B. Rainsberger's talk "Integrated Tests Are A Scam" people have been thinking how to get the confidence we need to deploy our software to production without having a tiresome integration test suite that does not give us all the coverage we think it does.

Pact is a ruby gem that allows you to define a pact between service consumers and providers. It provides a DSL for service consumers to define the request they will make to a service producer and the response they expect back. This expectation is used in the consumers specs to provide a mock producer, and is also played back in the producer specs to ensure the producer actually does provide the response the consumer expects.

This allows you to test both sides of an integration point using fast unit tests.

## Step 1 - Simple customer calling Provider

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

## Step 2 - Client Tested but integration fails

Now lets get the client to use the data it gets back from the provider. Here is the updated client method that uses the returned data:

client.rb

```ruby
      def process_data
        data = load_provider_json
        ap data
        value = 100 / data['count']
        date = Time.parse(data['date'])
        puts value
        puts date
        [value, date]
      end
```

Add a spec to test this client:

client_spec.rb:

```ruby
    require 'spec_helper'
    require 'client'


    describe Client do


      let(:json_data) do
        {
          "test" => "NO",
          "date" => "2013-08-16T15:31:20+10:00",
          "count" => 100
        }
      end
      let(:response) { double('Response', :success? => true, :body => json_data.to_json) }


      it 'can process the json payload from the provider' do
        HTTParty.stub(:get).and_return(response)
        expect(subject.process_data).to eql([1, Time.parse(json_data['date'])])
      end

    end
```

Let's run this spec and see it all pass:

```console
    $ rake spec
    /home/ronald/.rvm/rubies/ruby-2.3.0/bin/ruby -I/home/ronald/.rvm/gems/ruby-2.3.0@example_pact/gems/rspec-core-3.4.3/lib:/home/ronald/.rvm/gems/ruby-2.3.0@example_pact/gems/rspec-support-3.4.1/lib /home/ronald/.rvm/gems/ruby-2.3.0@example_pact/gems/rspec-core-3.4.3/exe/rspec --pattern spec/\*\*\{,/\*/\*\*\}/\*_spec.rb

    Client
    {
         "test" => "NO",
         "date" => "2013-08-16T15:31:20+10:00",
        "count" => 100
    }
    1
    2013-08-16 15:31:20 +1000
      can process the json payload from the provider

    Finished in 0.00582 seconds (files took 0.09577 seconds to load)
    1 example, 0 failures
```

However, there is a problem with this integration point. The provider returns a 'valid_date' while the consumer is trying to use 'date', which will blow up when run for real even with the tests all passing. Here is where Pact comes in.
