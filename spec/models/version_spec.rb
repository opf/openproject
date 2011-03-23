require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Version do
  let(:version) { Factory.build(:version) }
  let(:project) { Factory.build(:project) }

  it { should have_one :version_setting }

  describe "Class Methods" do
    describe :displayed_left do
      describe "WITH display set to left" do
        before(:each) do
          version.version_setting = Factory.build(:version_setting, :display => VersionSetting::DISPLAY_LEFT)
          version.project = project
          version.save!
        end

        it { Version.displayed_left(project).should eql [version] }
      end

      describe "WITH no version setting defined" do
        before(:each) do
          version.project = project
          version.save!
        end

        it { Version.displayed_left(project).should eql [version] }
      end
    end

    describe :displayed_right do
      before(:each) do
        version.version_setting = Factory.build(:version_setting, :display => VersionSetting::DISPLAY_RIGHT)
        version.project = project
        version.save!
      end

      it { Version.displayed_right(project).should eql [version] }
    end
  end
end