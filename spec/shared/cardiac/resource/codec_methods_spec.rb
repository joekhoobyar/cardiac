require 'spec_helper'

describe Cardiac::CodecMethods do
  
  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
    
  subject { resource }

  describe 'decoders built with' do
    subject do
      lambda{|*v| builder[resource, *v] ; resource.send(:build_decoders).keys }
    end
    
    after :each do
      decoders = resource.send(:build_decoders)
      expect(resource.reset_decoders.send(:build_decoders).keys).to eq(Cardiac::CodecMethods::DEFAULT_DECODERS)
      expect(resource.decoders(*decoders.keys).send(:build_decoders).keys).to eq(decoders.keys)
    end
    
    describe :decoders do
      context do
        let(:builder) { lambda{|r,*v| r.decoders(*v) } }
      
        describe '[:xml]' do
          subject { super()[:xml] }
          it { is_expected.to eq([:xml]) }
        end

        describe '[:json]' do
          subject { super()[:json] }
          it { is_expected.to eq([:json]) }
        end

        describe '[:xml, :json, :xml]' do
          subject { super()[:xml, :json, :xml] }
          it { is_expected.to eq([:xml, :json]) }
        end
      end
      
      context do
        let(:builder) { lambda{|r,*l| l.each{|v| r.decoders(*v) } } }
      
        describe '[[:xml]]' do
          subject { super()[[:xml]] }
          it { is_expected.to eq([:xml]) }
        end

        describe '[[:xml],[:json]]' do
          subject { super()[[:xml],[:json]] }
          it { is_expected.to eq([:xml, :json]) }
        end

        describe '[[:xml, :json], [:url_encoded, :xml]]' do
          subject { super()[[:xml, :json], [:url_encoded, :xml]] }
          it { is_expected.to eq([:xml, :json, :url_encoded]) }
        end
      end
    end
    
  end
end