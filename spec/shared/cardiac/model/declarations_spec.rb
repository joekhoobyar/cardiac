require 'spec_helper'

describe Cardiac::Model::Base do
  
  include_context 'Client responses'
  
  let!(:klass) { Dummy }
  
  subject { klass }
    
  describe '#base_resource' do
    subject { super().base_resource }
      
    it { is_expected.to be_a(::Cardiac::Resource) }
      
    describe '#to_url' do
      subject { super().to_url }
      it { is_expected.to eq('http://localhost/dummy') }
    end
  end
    
  it { is_expected.to     respond_to(:find_instances)  }
  it { is_expected.to     respond_to(:create_instance) }
  it { is_expected.to     respond_to(:identify)        }
  it { is_expected.not_to respond_to(:find_instance)   }
  it { is_expected.not_to respond_to(:update_instance) }
  it { is_expected.not_to respond_to(:delete_instance) }
  
  describe '#identify' do
    let(:id_or_model) { 1 }
      
    subject { klass.identify(id_or_model) }
    
    it { is_expected.not_to respond_to(:find_instances)  }
    it { is_expected.not_to respond_to(:create_instance) }
    it { is_expected.not_to respond_to(:identify)        }
    it { is_expected.to     respond_to(:find_instance)   }
    it { is_expected.to     respond_to(:update_instance) }
    it { is_expected.to     respond_to(:delete_instance) }
      
    it 'CGI escapes strings' do
      bad_path = 'bad/string&?'
      good_path = CGI.escape(bad_path)
      
      expect(CGI).to receive(:escape).once.and_call_original
      
      expect(klass.identify(bad_path).to_url).to eq('http://localhost/dummy/'+good_path)  
    end
      
    it 'CGI escapes arrays' do
      bad_path = ['bad&','string&?']
      good_path = [CGI.escape('bad&'), CGI.escape('string&?')]
      
      expect(CGI).to receive(:escape).twice.and_call_original
      
      expect(klass.identify(bad_path).to_url).to eq('http://localhost/dummy/'+good_path.to_param)  
    end
  end
  
  describe '#with_resource()' do
    subject { klass.with_resource{|x| x.get } }
      
    # Mock the REST execution, using the :mock_success stubbed out response...
    include_context 'Client execution', :get, :success
     
    it { is_expected.to be_a(Hash) }
      
    describe "['segment']" do
      subject { super()['segment'] }
      it { is_expected.to eq({'id'=>1, 'name'=>'John Doe'}) }
    end
  end
  
end