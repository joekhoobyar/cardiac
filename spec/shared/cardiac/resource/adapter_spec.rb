require 'spec_helper'

describe Cardiac::ResourceAdapter do
  
  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
  let(:adapter)  { Cardiac::ResourceAdapter.new(nil, resource) }
    
  include_context 'Client responses'
    
  subject { adapter }
    
  describe '#http_verb' do
    subject { super().http_verb }
    it { is_expected.to be_nil }
  end

  describe '#payload' do
    subject { super().payload }
    it { is_expected.to be_nil }
  end

  describe '#response' do
    subject { super().response }
    it { is_expected.to be_nil }
  end

  describe '#result' do
    subject { super().result }
    it { is_expected.to be_nil }
  end

  describe '#resource' do
    subject { super().resource }
    it { is_expected.to eq(resource) }
  end
    
  it { is_expected.to be_resolved }
    
  describe '#call!()' do
    
    describe 'successful responses' do
      include_context 'Client execution', :get, :success
      
      before :example do
        resource.http_method(:get)
        expect { @retval = adapter.call! }.not_to raise_error
      end
      
      describe '#response' do
        subject { adapter.response }
        it { is_expected.to be_present }
      end

      describe '#result' do
        subject { adapter.result }
        it { is_expected.to be_present }
      end
        
      it('returns true')   { expect(@retval).to be_a(TrueClass) }
    end
    
    describe 'failed responses' do
      include_context 'Client execution', :get, :failure
      
      before :example do
        resource.http_method(:get)
        expect { @retval = adapter.call! }.to raise_error
      end
      
      describe '#response' do
        subject { adapter.response }
        it { is_expected.not_to be_present }
      end

      describe '#result' do
        subject { adapter.result }
        it { is_expected.not_to be_present }
      end
    end
  end
end