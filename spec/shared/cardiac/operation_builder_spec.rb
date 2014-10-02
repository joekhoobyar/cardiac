require 'spec_helper'

describe Cardiac::OperationBuilder do

  let(:base_url) { 'http://localhost/prefix/segment?q=foobar' }
  let(:base_uri) { URI(base_url) }
  let(:resource) { Cardiac::Resource.new(base_uri) }
  let(:builder)  { Cardiac::OperationBuilder.new(resource.dup) }

  subject { builder }

  shared_examples 'a URI builder' do |args,url|
    calldesc = "##{args[0]}(#{args[1..-1].map(&:inspect).join(',')})"

    subject { builder.send(*args) }

    it "#{calldesc} should modify the new builder" do
      expect(subject.to_resource.to_url).to eq(url)
      unless url == base_url
        expect(subject.to_resource.to_uri).not_to eq(base_uri)
        expect(subject.to_resource.to_url).not_to eq(base_url)
      end
    end

    it "#{calldesc} should not modify the original builder" do
      unless url == base_url
        expect(builder.to_resource.to_uri).to eq(base_uri)
        expect(builder.to_resource.to_url).to eq(base_url)
      end
    end
  end

  shared_examples 'a call builder' do |verb|
    it { is_expected.to respond_to(verb) }

    describe "##{verb}" do
      subject { builder.send(verb, *args).to_resource }
      let!(:args) { [] }

      if verb==:call
        describe '#method_value' do
          subject { super().method_value }
          it { is_expected.to be_nil }
        end
      else
        describe '#method_value' do
          subject { super().method_value }
          it { is_expected.to eq(verb) }
        end
      end
    end
  end

  shared_examples 'a call proxy' do |verb, mock|
    it { is_expected.to respond_to(verb) }
  
    include_context 'Client responses'

    describe "##{verb}" do
      include_context 'Client execution', verb, mock
      
      subject { builder.send(verb, *args) }
      let!(:args) { [] }
        
      it 'should not raise an error' do
        expect { subject.to_s }.not_to raise_error
      end
    end
  end

  shared_examples 'URI building' do
    it_behaves_like 'a URI builder', [:scheme, 'https'],     'https://localhost/prefix/segment?q=foobar'
    it_behaves_like 'a URI builder', [:https],               'https://localhost/prefix/segment?q=foobar'
    it_behaves_like 'a URI builder', [:host, 'google.com'],  'http://google.com/prefix/segment?q=foobar'
    it_behaves_like 'a URI builder', [:port, 8080],          'http://localhost:8080/prefix/segment?q=foobar'
    it_behaves_like 'a URI builder', [:path, '1'],           'http://localhost/prefix/segment/1?q=foobar'
    it_behaves_like 'a URI builder', [:query, 'q=barfoo'],   'http://localhost/prefix/segment?q=barfoo'
    it_behaves_like 'a URI builder', [:query, {q: 1, r: 2}], 'http://localhost/prefix/segment?q=1&r=2'
  end
  
  include_examples 'URI building'

  it_behaves_like 'a call builder', :get
  it_behaves_like 'a call builder', :post
  it_behaves_like 'a call builder', :put
  it_behaves_like 'a call builder', :delete

  describe Cardiac::OperationProxy do
    let(:builder)  { Cardiac::OperationProxy.new(resource.dup) }
     
    include_examples 'URI building'
    
    it_behaves_like 'a call proxy', :get, :success
  end

end