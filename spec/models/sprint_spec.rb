require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Sprint do
  let(:sprint) { Factory.build(:sprint) }
  let(:project) { Factory.build(:project) }

  describe "Class Methods" do
    describe :displayed_left do
      describe "WITH display set to left" do
        before(:each) do
          sprint.version_setting = Factory.build(:version_setting, :display => VersionSetting::DISPLAY_LEFT)
          sprint.project = project
          sprint.save!
        end

        it { Sprint.displayed_left(project).should eql [sprint] }
      end

      describe "WITH no version setting defined" do
        before(:each) do
          sprint.project = project
          sprint.save!
        end

        it { Sprint.displayed_left(project).should eql [sprint] }
      end
    end

    describe :displayed_right do
      before(:each) do
        sprint.version_setting = Factory.build(:version_setting, :display => VersionSetting::DISPLAY_RIGHT)
        sprint.project = project
        sprint.save!
      end

      it { Sprint.displayed_right(project).should eql [sprint] }
    end

    describe :order_by_date do
      before(:each) do
        @sprint1 = Factory.create(:sprint, :name => "sprint1", :project => project, :sprint_start_date => Date.today + 2.days)
        @sprint2 = Factory.create(:sprint, :name => "sprint2", :project => project, :sprint_start_date => Date.today + 1.day, :effective_date => Date.today + 3.days)
        @sprint3 = Factory.create(:sprint, :name => "sprint3", :project => project, :sprint_start_date => Date.today + 1.day, :effective_date => Date.today + 2.days)
      end

      it { Sprint.order_by_date[0].should eql @sprint3 }
      it { Sprint.order_by_date[1].should eql @sprint2 }
      it { Sprint.order_by_date[2].should eql @sprint1 }
    end
  end
end