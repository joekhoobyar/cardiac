require 'spec_helper'

describe Cardiac::Representation::Reflection do
  
  shared_context 'by extension' do |_extension,*rest|
    let(:extension) { _extension }
    subject { described_class.new(extension, *rest) }
  end
  
  shared_examples 'default type' do |*rest|
    describe '#extension' do
      subject { super().extension }
      it { is_expected.to eq(extension) }
    end

    describe '#default_type' do
      subject { super().default_type }
      it { is_expected.to be_present }
    end

    describe '#types' do
      it 'includes the default type' do
        expect(subject.types).to be_include(subject.default_type)
      end
      it 'includes the application/:extension type' do
        expect(subject.types).to be_include("application/#{extension}")
      end
    end
  end
  
  shared_examples 'default coder' do
    describe '#coder' do
      subject { super().coder }
      it { is_expected.to eq(::Cardiac::Representation::Codecs.const_get(extension.to_s.classify)) }
    end

    describe '#coder' do
      subject { super().coder }
      it { is_expected.to be_respond_to(:decode) }
    end

    describe '#coder' do
      subject { super().coder }
      it { is_expected.to be_respond_to(:encode) }
    end
  end
  
  describe 'JSON' do
    include_context  'by extension', :json
    include_examples 'default type'
    include_examples 'default coder'
  end
  
  describe 'XML' do
    include_context  'by extension', :xml
    include_examples 'default type'
    include_examples 'default coder'
    
    describe '#types' do
      subject { super().types }
      it { is_expected.to be_include("text/xml") }
    end
  end
  
  describe 'unknown' do
    include_context  'by extension', :unknown
    
    it 'cannot be created' do
      expect { subject }.to raise_error
    end
  end
  
end