require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VersionSetting do
  let(:version_setting) { Factory.build(:version_setting) }

  it { should belong_to(:project) }
  it { should belong_to(:version) }
  it { VersionSetting.column_names.should include("display") }

  describe "Instance Methods" do
    describe "WITH display set to left" do
      before(:each) do
        version_setting.display_left!
      end

      it { version_setting.display_left?.should be_true }
    end

    describe "WITH display set to right" do
      before(:each) do
        version_setting.display_right!
      end

      it { version_setting.display_right?.should be_true }
    end

    describe "WITH display set to none" do
      before(:each) do
        version_setting.display_none!
      end

      it { version_setting.display_none?.should be_true }
    end
  end
end