require 'spec_helper'

describe Cardiac::DeclarationMethods do
  let!(:target)     { double().extend(described_class) }
    
  let! :foobar_extensions do
    Proc.new do
      https.path('/foo/bar').headers(content_type: 'application/octet-stream')
      
      def foobar
        path('/foobar').reset_headers
      end
    end
  end
  
  shared_examples 'a resource declaration' do |base,mock|
    if mock.present?
      let(:extensions) { send(:"#{mock}_extensions") }
    end
      
    subject { target.resource(base, &extensions) }

    if Cardiac::Resource === base
      it { is_expected.to be_a(Cardiac::Subresource) }
    else
      it { is_expected.to be_a(Cardiac::Resource) }
    end      
  end
  
  describe '#resource()' do
    let(:default_headers) { {:accepts => Cardiac::RequestMethods::DEFAULT_ACCEPTS } } 
      
    it_behaves_like 'a resource declaration', 'http://localhost/', :foobar do
      describe '#to_url' do
        subject { super().to_url }
        it { is_expected.to eq('https://localhost/foo/bar') }
      end

      describe '#build_headers' do
        subject { super().send(:build_headers) }
        it { is_expected.to eq(default_headers.merge(:content_type => 'application/octet-stream')) }
      end
        
      it { is_expected.not_to respond_to(:foobar) }
        
      describe '#__extension_module__' do
        subject { super().__extension_module__ }
        it { is_expected.to be_method_defined(:foobar) }
      end
    end
  end
end

describe Cardiac::Declarations do
  let(:base)   { 'http://example.com' }
  
  shared_examples 'a declared resource' do |klass|
    subject! { klass.tap{|x| x.send(:include,described_class) } }
  
    before :example do
      klass.resource(base) do
        https.option(:timeout, 6)
        
        def foobar
          :barfoo
        end
      end
    end
      
    it { is_expected.to respond_to(:base_resource) }
    it { is_expected.not_to be_method_defined(:base_resource) }
      
    describe '#base_resource' do
      subject { super().base_resource }
      it { is_expected.to be_present }
    end

    describe '#base_resource' do
      subject { super().base_resource }
      describe '#to_url' do
        subject { super().to_url }
        it { is_expected.to eq('https://example.com/') }
      end
    end

    describe '#base_resource' do
      subject { super().base_resource }
      describe '#options_values' do
        subject { super().options_values }
        it { is_expected.to eq([{timeout: 6}]) }
      end
    end
  end
  
  describe 'when mixed into a class' do
    include_examples 'a declared resource', Class.new
  end
  
  describe 'when mixed into a module' do
    include_examples 'a declared resource', Module.new
  end
  
end