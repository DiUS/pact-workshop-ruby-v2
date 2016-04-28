require 'pact/consumer/rspec'

Pact.service_consumer "Our Consumer" do
  has_pact_with "Our Provider" do
    mock_service :our_provider do
      port 1234
    end
  end
end
