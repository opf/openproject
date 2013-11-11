require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Sprint do
  let(:sprint) { FactoryGirl.build(:sprint) }
  let(:project) { FactoryGirl.build(:project) }

  describe "Class Methods" do
    describe :displayed_left do
      describe "WITH display set to left" do
        before(:each) do
          sprint.version_settings = [FactoryGirl.build(:version_setting, :project => project,
                                                                     :display => VersionSetting::DISPLAY_LEFT)]
          sprint.project = project
          sprint.save!
        end

        it {
          Sprint.displayed_left(project).should match_array [sprint] }
      end

      describe "WITH a version setting defined for another project" do
        before(:each) do
          another_project = FactoryGirl.build(:project, :name => 'another project',
                                                   :identifier => 'another project')

          sprint.version_settings = [FactoryGirl.build(:version_setting, :project => another_project,
                                                                     :display => VersionSetting::DISPLAY_RIGHT)]
          sprint.project = project
          sprint.save
        end

        it { Sprint.displayed_left(project).should match_array [sprint] }
      end

      describe "WITH no version setting defined" do
        before(:each) do
          sprint.project = project
          sprint.save!
        end

        it { Sprint.displayed_left(project).should match_array [sprint] }
      end
    end

    describe :displayed_right do
      before(:each) do
        sprint.version_settings = [FactoryGirl.build(:version_setting, :project => project, :display => VersionSetting::DISPLAY_RIGHT)]
        sprint.project = project
        sprint.save!
      end

      it { Sprint.displayed_right(project).should match_array [sprint] }
    end

    describe :order_by_date do
      before(:each) do
        @sprint1 = FactoryGirl.create(:sprint, :name => "sprint1", :project => project, :start_date => Date.today + 2.days)
        @sprint2 = FactoryGirl.create(:sprint, :name => "sprint2", :project => project, :start_date => Date.today + 1.day, :effective_date => Date.today + 3.days)
        @sprint3 = FactoryGirl.create(:sprint, :name => "sprint3", :project => project, :start_date => Date.today + 1.day, :effective_date => Date.today + 2.days)
      end

      it { Sprint.order_by_date[0].should eql @sprint3 }
      it { Sprint.order_by_date[1].should eql @sprint2 }
      it { Sprint.order_by_date[2].should eql @sprint1 }
    end

    describe :apply_to do
      before(:each) do
        project.save
        @other_project = FactoryGirl.create(:project)
      end

      describe "WITH the version beeing shared system wide" do
        before(:each) do
          @version = FactoryGirl.create(:sprint, :name => "systemwide", :project => @other_project, :sharing => 'system')
        end

        it { Sprint.apply_to(project).should have(1).entry }
        it { Sprint.apply_to(project)[0].should eql(@version) }
      end

      describe "WITH the version beeing shared from a parent project" do
        before(:each) do
          project.set_parent!(@other_project)
          @version = FactoryGirl.create(:sprint, :name => "descended", :project => @other_project, :sharing => 'descendants')
        end

        it { Sprint.apply_to(project).should have(1).entry }
        it { Sprint.apply_to(project)[0].should eql(@version) }
      end

      describe "WITH the version beeing shared within the tree" do
        before(:each) do
          @parent_project = FactoryGirl.create(:project)
          # Setting the parent has to be in this order, don't know why yet
          @other_project.set_parent!(@parent_project)
          project.set_parent!(@parent_project)
          @version = FactoryGirl.create(:sprint, :name => "treed", :project => @other_project, :sharing => 'tree')
        end

        it { Sprint.apply_to(project).should have(1).entry }
        it { Sprint.apply_to(project)[0].should eql(@version) }
      end

      describe "WITH the version beeing shared within the tree" do
        before(:each) do
          @descendant_project = FactoryGirl.create(:project)
          @descendant_project.set_parent!(project)
          @version = FactoryGirl.create(:sprint, :name => "hierar", :project => @descendant_project, :sharing => 'hierarchy')
        end

        it { Sprint.apply_to(project).should have(1).entry }
        it { Sprint.apply_to(project)[0].should eql(@version) }
      end
    end
  end
end
