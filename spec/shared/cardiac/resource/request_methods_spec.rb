require 'spec_helper'

describe Cardiac::RequestMethods do
  
  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
  let(:default_headers) { {:accepts => Cardiac::RequestMethods::DEFAULT_ACCEPTS } }
    
  subject { resource }

  describe 'headers built with' do
    subject do
      lambda{|*v| builder[resource, *v] ; resource.send(:build_headers).symbolize_keys.except(:accepts) }
    end
    
    after :each do
      headers = resource.send(:build_headers)
      expect(resource.reset_headers.send(:build_headers)).to eq(default_headers)
      expect(resource.headers(headers).send(:build_headers)).to eq(headers)
    end
    
    shared_examples 'header building' do |builder|
      let(:builder) { builder }
      
      describe "[{content_type: 'application/xml'}]" do
        subject { super()[{content_type: 'application/xml'}] }
        it { is_expected.to eq({content_type: 'application/xml'}) }
      end
      
      describe "[{content_type: 'application/xml'},{content_type: 'application/json'}]" do
        subject { super()[{content_type: 'application/xml'},{content_type: 'application/json'}] }

        it 'has 1 item' do
        is_expected.to eq({content_type: 'application/json'})
        expect(subject.size).to eq(1)
      end
      end
      
      describe "[{'content_type' => 'application/json'},{content_type: 'application/xml'}]" do
        subject { super()[{'content_type' => 'application/json'},{content_type: 'application/xml'}] }

        it 'has 1 item' do
        is_expected.to eq({content_type: 'application/xml'})
        expect(subject.size).to eq(1)
      end
      end
    end
    
    describe '#headers()' do
      include_examples 'header building', lambda{|r,*v| r.headers(*v) }
        
      describe "[{content_type: 'application/xml'},{content_type: false}]" do
        subject { super()[{content_type: 'application/xml'},{content_type: false}] }
        it { is_expected.to eq({content_type: false}) }
      end
    end
    
    describe '#header()' do
      let(:builder) { lambda{|r,*l| l.each{|k,v| r.header(k,v) } } }
      
      describe "[[:content_type, 'application/xml']]" do
        subject { super()[[:content_type, 'application/xml']] }
        it { is_expected.to eq({content_type: 'application/xml'}) }
      end

      describe "[['content_type', 'application/json']]" do
        subject { super()[['content_type', 'application/json']] }
        it { is_expected.to eq({content_type: 'application/json'}) }
      end

      describe "[[:content_type, 'application/json'],['content_type', false]]" do
        subject { super()[[:content_type, 'application/json'],['content_type', false]] }
        it { is_expected.to eq({}) }
      end

      describe "[['content_type', 'application/json'],[:content_type, false]]" do
        subject { super()[['content_type', 'application/json'],[:content_type, false]] }
        it { is_expected.to eq({}) }
      end

      describe "[[:content_type, false],[:content_type, 'application/xml']]" do
        subject { super()[[:content_type, false],[:content_type, 'application/xml']] }
        it { is_expected.to eq({content_type: 'application/xml'}) }
      end

      describe "[['content_type', false],['content_type', 'application/json']]" do
        subject { super()[['content_type', false],['content_type', 'application/json']] }
        it { is_expected.to eq({content_type: 'application/json'}) }
      end
      
      describe "[[:content_type,'application/xml'],[:content_type,'application/json']]" do
        subject { super()[[:content_type,'application/xml'],[:content_type,'application/json']] }

        it 'has 1 item' do
        is_expected.to eq({content_type: 'application/json'})
        expect(subject.size).to eq(1)
      end
      end
      
      describe "[['content_type', 'application/json'],[:content_type,'application/xml']]" do
        subject { super()[['content_type', 'application/json'],[:content_type,'application/xml']] }

        it 'has 1 item' do
        is_expected.to eq({content_type: 'application/xml'})
        expect(subject.size).to eq(1)
      end
      end
    end
    
    describe '#options()' do
      include_examples 'header building', lambda{|r,*l| l.each{|o| r.options(headers: o) } }
        
      describe "[{content_type: 'application/xml'},{content_type: false}]" do
        subject { super()[{content_type: 'application/xml'},{content_type: false}] }
        it { is_expected.to eq({content_type: false}) }
      end
    end
  end
  
  describe 'options built with' do
    subject do
      lambda{|*v| builder[resource, *v] ; resource.send(:build_options) }
    end
    
    after(:each) do
      options = resource.send(:build_options)
      expect(resource.reset_options.send(:build_options)).to eq({})
      expect(resource.options(options).send(:build_options)).to eq(options)
    end
    
    describe '#options()' do
      let(:builder){ lambda{|r,*v| r.options(*v) } }
      
      describe '[{timeout: 60}]' do
        subject { super()[{timeout: 60}] }
        it { is_expected.to eq({timeout: 60}) }
      end
      
      describe '[{timeout: 60},{timeout: 30}]' do
        subject { super()[{timeout: 60},{timeout: 30}] }

        it 'has 1 item' do
        is_expected.to eq({timeout: 30})
        expect(subject.size).to eq(1)
      end
      end
      
      describe "[{'timeout' => 60},{timeout: 30}]" do
        subject { super()[{'timeout' => 60},{timeout: 30}] }

        it 'has 1 item' do
        is_expected.to eq({timeout: 30})
        expect(subject.size).to eq(1)
      end
      end
    end
    
    describe '#option()' do
      let(:builder){ lambda{|r,*l| l.each{|k,v| r.option(k,v) } } }
  
      describe '[[:timeout, 60]]' do
        subject { super()[[:timeout, 60]] }
        it { is_expected.to eq({timeout: 60}) }
      end
        
      describe '[[:timeout, 60],[:timeout, 30]]' do
        subject { super()[[:timeout, 60],[:timeout, 30]] }

        it 'has 1 item' do
        is_expected.to eq({timeout: 30})
        expect(subject.size).to eq(1)
      end
      end
      
      describe "[['timeout',  60],[:timeout, 30]]" do
        subject { super()[['timeout',  60],[:timeout, 30]] }

        it 'has 1 item' do
        is_expected.to eq({timeout: 30})
        expect(subject.size).to eq(1)
      end
      end
    end
  end
end