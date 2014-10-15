require 'spec_helper'

describe Cardiac::Model::Base do
  
  include_context 'Client responses'
  
  let! :klass do
    Class.new(Cardiac::Model::Base).class_eval do
      self.base_resource = 'http://localhost/dummy'
      
      attribute :id,     type: Integer
      attribute :name,   type: String
      
      def self.name; 'Dummy' end
      
      self
    end
  end
   
  subject { klass }
    
  describe '#base_resource' do
    subject { super().base_resource }
    it { is_expected.to be_a(::Cardiac::Resource) }
  end

  describe '#base_resource' do
    subject { super().base_resource }
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
  
  describe '#identify' do
    subject { klass.identify(1) }
    
    it { is_expected.not_to respond_to(:find_instances)  }
    it { is_expected.not_to respond_to(:create_instance) }
    it { is_expected.not_to respond_to(:identify)        }
    it { is_expected.to     respond_to(:find_instance)   }
    it { is_expected.to     respond_to(:update_instance) }
    it { is_expected.to     respond_to(:delete_instance) }
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