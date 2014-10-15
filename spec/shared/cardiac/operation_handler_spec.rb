require 'spec_helper'

describe Cardiac::OperationHandler do
  
  let(:resource)       { Cardiac::Resource.new('http://google.com') }
  let(:payload)        { }
  let(:client_handler) { }
  
  subject do
    handler = described_class.new(resource.send(:build_client_options), payload, &client_handler)
    handler.config.update(resource.send(:build_config))
    handler
  end
    
  include_context 'Client responses'
    
  shared_examples 'successful responses' do |verb|
    include_context 'Client execution', verb, :success
    
    before :example do
      resource.http_method(verb)
      expect{ subject.transmit! }.not_to raise_error
    end
    
    it { is_expected.to be_completed }
    it { is_expected.to be_transmitted }
    it { is_expected.not_to be_aborted }
  end
  
  shared_examples 'unsuccessful responses' do |verb|
    include_context 'Client execution', verb, :failure
    
    before :example do
      resource.http_method(verb)
      expect{ subject.transmit! }.to raise_error(/Not Found/)
    end
    
    it { is_expected.not_to be_completed }
    it { is_expected.to be_transmitted }
    it { is_expected.to be_aborted }
  end
  
  shared_examples 'aborted requests' do |verb|
    before :example do
      allow_any_instance_of(Cardiac::OperationHandler).to receive(:perform_request){|_| raise Errno::ECONNREFUSED }
      resource.http_method(verb)
    end
    
    describe 'that mock a response on connection errors' do
      before :example do
        resource.mock_response_on_connection_error = true
        expect{ subject.transmit! }.not_to raise_error
      end
      
      it { is_expected.not_to be_transmitted }
      it { is_expected.to be_completed }
      it { is_expected.not_to be_aborted }
    end
    
    describe 'that raise connection errors' do
      before :example do
        resource.mock_response_on_connection_error = false
        expect{ subject.transmit! }.to raise_error(Errno::ECONNREFUSED)
      end
      it { is_expected.not_to be_transmitted }
      it { is_expected.not_to be_completed }
      it { is_expected.to be_aborted }
    end
  end
  
  describe 'GET' do
    it_behaves_like 'successful responses', :get
    it_behaves_like 'unsuccessful responses', :get
    it_behaves_like 'aborted requests', :get
  end
  
  describe 'POST' do
    it_behaves_like 'successful responses', :post
    it_behaves_like 'unsuccessful responses', :post
    it_behaves_like 'aborted requests', :post
  end
  
  describe 'PUT' do
    it_behaves_like 'successful responses', :put
    it_behaves_like 'unsuccessful responses', :put
    it_behaves_like 'aborted requests', :put
  end
  
  describe 'DELETE' do
    it_behaves_like 'successful responses', :delete
    it_behaves_like 'unsuccessful responses', :delete
    it_behaves_like 'aborted requests', :delete
  end
  
  it 'will not transmit without an HTTP verb' do
    resource.http_method(nil)
    expect { subject.transmit! }.to raise_error(Cardiac::InvalidOperationError)
  end
  
end