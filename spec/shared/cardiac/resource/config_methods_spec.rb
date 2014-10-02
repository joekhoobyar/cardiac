require 'spec_helper'

describe Cardiac::ConfigMethods do
  
  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
    
  subject { resource }
    
  it { expect{ subject.send(:build_config) }.not_to raise_error }

  describe 'config built with' do
    subject do
      lambda{|*v| builder[resource, *v] ; resource.send(:build_config) }
    end
    
    before :example do
      @original_config = resource.send(:build_config)
    end
    
    after :each do
      config = resource.send(:build_config)
      resource.reconfig
      expect(resource.send(:build_config)).to eq(@original_config)
      resource.config.update(config)
      expect(resource.send(:build_config)).to eq(config)
    end
    
    describe '#config()' do
      describe 'unwrap_client_exceptions: ...' do
        let(:builder) { lambda{|r,*v| v.each{|h| r.config.update(h) } } }
      
        describe '[{unwrap_client_exceptions: true}]' do
          subject { super()[{unwrap_client_exceptions: true}] }
          it { is_expected.to eq({unwrap_client_exceptions: true})  }
        end

        describe '[{unwrap_client_exceptions: false}]' do
          subject { super()[{unwrap_client_exceptions: false}] }
          it { is_expected.to eq({unwrap_client_exceptions: false}) }
        end
        
        it do
          expect(resource.unwrap_client_exceptions).to be_falsey
          expect(resource.config).to be_empty
        end
      end
    end
    
  end
end