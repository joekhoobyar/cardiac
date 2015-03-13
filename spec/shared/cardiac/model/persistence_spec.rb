require 'spec_helper'

describe Cardiac::Model::Base do
  
  include_context 'Client responses'
  
  let!(:klass) { Dummy }
  
  subject { klass }
    
  shared_examples 'administering records' do
    describe '#id' do
      subject { super().id }
      it { is_expected.to eq(1) }
    end

    describe '#to_key' do
      subject { super().to_key }
      it { is_expected.to eq([1]) }
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('Jane Doe') }
    end

    describe '#remote_attributes' do
      subject { super().remote_attributes }
      it { is_expected.to eq('id' => 1, 'name' => 'John Doe') }
    end

    describe '#changed' do
      subject { super().changed }
      it { is_expected.to be_empty }
    end
  end
  
  shared_examples 'read-only models prohibit modification' do
    before(:each) { klass.readonly = true }
    after(:each) { klass.readonly = false }
    it('raises an error') { expect{ subject }.to raise_error }
  end
  
  describe '#create' do
    subject { klass.create }
      
    context do
      # Mock the REST execution, using the :mock_success stubbed out response...
      include_context 'Client execution', :post, :success
     
      it { is_expected.to be_persisted }
      it { is_expected.not_to be_destroyed }
      it { is_expected.not_to be_new_record }
        
      describe '#id' do
        subject { super().id }
        it { is_expected.to eq(1)   }
      end

      describe '#to_key' do
        subject { super().to_key }
        it { is_expected.to eq([1]) }
      end

      describe '#to_param' do
        subject { super().to_param }
        it { is_expected.to eq('1') }
      end

      describe '#name' do
        subject { super().name }
        it { is_expected.to be_nil }
      end   # remote attributes ignored by default on creation.

      describe '#remote_attributes' do
        subject { super().remote_attributes }
        it { is_expected.not_to be_empty }
      end

      describe '#changed' do
        subject { super().changed }
        it { is_expected.to be_empty }
      end
      
      it 'should store the remote attributes' do
        expect(subject.remote_attributes['id']).to eq(1)
        expect(subject.remote_attributes[:name]).to eq('John Doe')
      end
    end
    
    it_behaves_like 'read-only models prohibit modification'
  end
  
  describe '#reload' do
    subject { klass.send(:instantiate, id: 1, name: 'Johnny Doe').tap{|r| r.name = 'Jane Doe' }.reload }
        
    # Mock the REST execution, using the :mock_success stubbed out response...
    include_context 'Client execution', :get, :success
       
    it { is_expected.to be_persisted }
    it { is_expected.not_to be_destroyed }
    it { is_expected.not_to be_new_record }
        
    describe '#id' do
      subject { super().id }
      it { is_expected.to eq(1) }
    end

    describe '#to_key' do
      subject { super().to_key }
      it { is_expected.to eq([1]) }
    end

    describe '#to_param' do
      subject { super().to_param }
      it { is_expected.to eq('1') }
    end

    describe '#name' do
      subject { super().name }
      it { is_expected.to eq('John Doe') }
    end

    describe '#remote_attributes' do
      subject { super().remote_attributes }
      it { is_expected.to be_empty }
    end

    describe '#changed' do
      subject { super().changed }
      it { is_expected.to be_empty }
    end
  end
  
  describe '#update' do
    subject { klass.send(:instantiate, id: 1, name: 'John Doe').tap{|r| r.update(name: 'Jane Doe') } }
          
    context do
      # Mock the REST execution, using the :mock_success stubbed out response...
      include_context 'Client execution', :put, :success
      include_context 'administering records'
      
      it { is_expected.to be_persisted }
      it { is_expected.not_to be_destroyed }
      it { is_expected.not_to be_new_record }
      it { is_expected.not_to be_name_changed }

      describe '#to_param' do
        subject { super().to_param }
        it { is_expected.to eq('1') }
      end
    end
    
    it_behaves_like 'read-only models prohibit modification'
  end

  describe '#delete' do
    subject { klass.send(:instantiate, id: 1, name: 'Jane Doe').tap(&:destroy) }
          
    context do
      # Mock the REST execution, using the :mock_success stubbed out response...
      include_context 'Client execution', :delete, :success
      include_context 'administering records'
      
      it { is_expected.to be_destroyed }
      it { is_expected.not_to be_new_record }
      it { is_expected.not_to be_name_changed }
      it { is_expected.not_to be_name_changed }

      describe '#to_param' do
        subject { super().to_param }
        it { is_expected.to be_nil }
      end
    end
    
    it_behaves_like 'read-only models prohibit modification'
  end
  
end