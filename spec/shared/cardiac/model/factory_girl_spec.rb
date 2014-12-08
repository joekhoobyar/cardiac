require "spec_helper"

describe Cardiac::Model::FactoryGirlRemoteStrategy do
  
  describe "building an existing instance" do
    let!(:widget) { FactoryGirl.remote(:widget, id: 1) }
      
    subject { widget }
    
    it { is_expected.to be_kind_of(Widget) }
    it { is_expected.to be_persisted }
    it { is_expected.not_to be_new_record }
      
    describe 'registering an URL with FakeWeb' do
      subject { Widget.find(1) }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    
      it { is_expected.to be_kind_of(Widget) }
      it { is_expected.to be_persisted }
      it { is_expected.not_to be_new_record }
    end
    
  end

end
