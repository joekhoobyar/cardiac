require 'spec_helper'

describe Cardiac::Model::Base do
  
  include_context 'Client responses'
  
  let!(:klass) { Dummy }
  
  subject { klass }
  
  shared_examples 'new records' do
    it { is_expected.not_to be_persisted }
    it { is_expected.to be_new_record }
      
    describe '#id' do
      subject { super().id }
      it { is_expected.to be_nil }
    end

    describe '#to_key' do
      subject { super().to_key }
      it { is_expected.to be_nil }
    end

    describe '#to_param' do
      subject { super().to_param }
      it { is_expected.to be_nil }
    end

    describe '#remote_attributes' do
      subject { super().remote_attributes }
      it { is_expected.to be_empty }
    end
  end
  
  describe '#new' do
    subject { klass.new }
      
    include_examples 'new records'
    
    it { is_expected.not_to be_name_changed }
    
    describe '#name' do
      subject { super().name }
      it { is_expected.to be_nil }
    end

    describe '#changed' do
      subject { super().changed }
      it { is_expected.to be_empty }
    end
      
    describe '(specifying initial attributes)' do
      subject { klass.new(name: 'Jane Doe') }
        
      include_examples 'new records'
      
      it { is_expected.to be_name_changed }
    
      describe '#name' do
        subject { super().name }
        it { is_expected.to eq('Jane Doe') }
      end

      describe '#changed' do
        subject { super().changed }
        it { is_expected.to eq(%w(name)) }
      end
    end
      
    describe '(changing initial attributes)' do
      subject { klass.new.tap{|r| r.name= 'Jane Doe'} }
        
      include_examples 'new records'
      
      it { is_expected.to be_name_changed }
    
      describe '#name' do
        subject { super().name }
        it { is_expected.to eq('Jane Doe') }
      end

      describe '#changed' do
        subject { super().changed }
        it { is_expected.to eq(%w(name)) }
      end
    end
  end
  
end