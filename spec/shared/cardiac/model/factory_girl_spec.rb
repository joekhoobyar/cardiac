require "spec_helper"

describe Cardiac::Model::FactoryGirlRemoteStrategy do
  
  describe "basic usage" do
    it "builds instance and registers get url with FakeWeb" do
      FactoryGirl.remote(:widget, id: 1)
      expect { Widget.find(1) }.not_to raise_error
      widget = Widget.find(1)
      widget.should be_kind_of Widget
    end
  end

end
