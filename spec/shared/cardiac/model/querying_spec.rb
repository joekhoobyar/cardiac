require 'spec_helper'

describe Cardiac::Model::Base do
  
  include_context 'Client responses'
  
  let!(:klass) { Dummy }
  
  subject { klass }
    
  shared_examples 'finding all instances' do
    
    # Require that the class itself receives the operation call. 
    before(:each) { expect(klass).to receive(:find_instances).and_call_original }
      
    describe 'when an Array is returned' do
      let(:mock_index_success) { mock_response_klass.new("[ #{mock_success.body} ]", mock_success.code, mock_success.headers) }
      
      # Mock the REST execution, using the :mock_success stubbed out response...
      include_context 'Client execution', :get, :index_success
     
      describe '#first' do
        subject { super().first }
        it { is_expected.to be_persisted }
      end

      describe '#first' do
        subject { super().first }
        it { is_expected.not_to be_new_record }
      end

      describe '#first' do
        subject { super().first }
        describe '#id' do
          subject { super().id }
          it { is_expected.to eq(1) }
        end
      end

      describe '#first' do
        subject { super().first }
        describe '#to_key' do
          subject { super().to_key }
          it { is_expected.to eq([1]) }
        end
      end

      describe '#first' do
        subject { super().first }
        describe '#to_param' do
          subject { super().to_param }
          it { is_expected.to eq('1') }
        end
      end

      describe '#first' do
        subject { super().first }
        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('John Doe') }
        end
      end

      describe '#first' do
        subject { super().first }
        describe '#remote_attributes' do
          subject { super().remote_attributes }
          it { is_expected.to be_empty }
        end
      end

      describe '#first' do
        subject { super().first }
        describe '#changed' do
          subject { super().changed }
          it { is_expected.to be_empty }
        end
      end
    end
      
    describe 'when an Array is not returned' do
      
      # Mock the REST execution, using the :mock_success stubbed out response...
      include_context 'Client execution', :get, :success
     
      it 'should raise an exception' do
        expect { subject.first }.to raise_error
      end
    end
  end
  
  describe '#find(id)' do
    subject { klass.find(1) }
      
    # Mock the REST execution, using the :mock_success stubbed out response...
    include_context 'Client execution', :get, :success
     
    it { is_expected.to be_persisted }
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
  
  describe '#find(:all)' do
    include_examples 'finding all instances' do
      subject { klass.find(:all) }
    end
  end
  
  describe '#all' do
    include_examples 'finding all instances' do
      subject { klass.all }
    end
  end
  
end