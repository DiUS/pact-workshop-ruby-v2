require 'pact/consumer/rspec'

Pact.service_consumer "Our Consumer" do
  has_pact_with "Our Provider" do
    mock_service :our_provider do
      port 1234
      pact_specification_version "2.0.0"
    end
  end
end
