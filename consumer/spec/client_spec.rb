require 'spec_helper'
require 'client'

describe Client do

  let(:json_data) do
    {
      "test" => "NO",
      "valid_date" => "2013-08-16T15:31:20+10:00",
      "count" => 100
    }
  end
  let(:response) { double('Response', :success? => true, :body => json_data.to_json) }

  it 'can process the json payload from the provider' do
    allow(HTTParty).to receive(:get).and_return(response)
    expect(subject.process_data(Time.now.httpdate)).to eql([1, Time.parse(json_data['valid_date'])])
  end

  describe 'Pact with our provider', :pact => true do

    subject { Client.new('localhost:1234') }

    let(:date) { Time.now.httpdate }

    describe "get json data" do

      before do
        our_provider.given("data count is > 0").
          upon_receiving("a request for json data").
          with(method: :get, path: '/provider.json', query: URI::encode('valid_date=' + date)).
          will_respond_with(
            status: 200,
            headers: {'Content-Type' => 'application/json'},
            body: {
              "test" => "NO",
              "valid_date" => Pact.term(
                  generate: "2013-08-16T15:31:20+10:00",
                  matcher: /\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}/),
              "count" => Pact.like(100)
            })
      end

      it "can process the json payload from the provider" do
        expect(subject.process_data(date)).to eql([1, Time.parse(json_data['valid_date'])])
      end

    end

    describe "handling invalid responses" do

      it "handles a missing date parameter" do
        our_provider.given("data count is > 0").
          upon_receiving("a request with a missing date parameter").
          with(method: :get, path: '/provider.json').
          will_respond_with(
            status: 400,
            headers: {'Content-Type' => 'application/json'},
            body: "valid_date is required"
          )
        expect(subject.process_data(nil)).to eql([0, nil])
      end

      it "handles an invalid date parameter" do
        our_provider.given("data count is > 0").
          upon_receiving("a request with an invalid date parameter").
          with(method: :get, path: '/provider.json', query: 'valid_date=This%20is%20not%20a%20date').
          will_respond_with(
            status: 400,
            headers: {'Content-Type' => 'application/json'},
            body: "'This is not a date' is not a date"
          )
        expect(subject.process_data('This is not a date')).to eql([0, nil])
      end

    end

    describe "when there is no data" do

      it "handles the 404 response" do
        our_provider.given("data count is == 0").
          upon_receiving("a request for json data").
          with(method: :get, path: '/provider.json', query: URI::encode('valid_date=' + date)).
          will_respond_with(status: 404)
        expect(subject.process_data(date)).to eql([0, nil])
      end

    end

  end

end
