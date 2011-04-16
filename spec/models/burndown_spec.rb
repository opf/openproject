require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Burndown do
  def set_attribute_journalized story, attribute, value, day
    story.instance_eval do @current_journal = nil end
    story.init_journal(user)
    story.send(attribute, value)
    story.current_journal.created_on = day
    story.save!
  end

  let(:user) { @user ||= Factory.create(:user) }
  let(:role) { @role ||= Factory.create(:role) }
  let(:tracker_feature) { @tracker_feature ||= Factory.create(:tracker_feature) }
  let(:tracker_task) { @tracker_task ||= Factory.create(:tracker_task) }
  let(:issue_priority) { @issue_priority ||= Factory.create(:priority, :is_default => true) }
  let(:version) { @version ||= Factory.create(:version, :project => project) }
  let(:sprint) { @sprint ||= Sprint.find(version.id) }

  let(:project) do
    unless @project
      @project = Factory.build(:project)
      @project.members = [Factory.build(:member, :principal => user,
                                                 :project => @project,
                                                 :roles => [role])]
      @project.versions << version
    end
    @project
  end

  let(:issue_open) { @status1 ||= Factory.create(:issue_status, :name => "status 1", :is_default => true) }
  let(:issue_closed) { @status2 ||= Factory.create(:issue_status, :name => "status 2", :is_closed => true) }

  before(:each) do
    Setting.plugin_redmine_backlogs = {:points_burn_direction => "down",
                                       :wiki_template => "",
                                       :card_spec => "Sattleford VM-5040",
                                       :story_trackers => [tracker_feature.id.to_s],
                                       :task_tracker => tracker_task.id.to_s }


    project.save
  end

  describe "Sprint Burndown" do
    describe "WITH the today date fixed to April 4th, 2011 and having a 10 (working days) sprint" do
      before(:each) do
        Time.stub!(:now).and_return(Time.utc(2011,"apr",4,20,15,1))
        Date.stub!(:today).and_return(Date.civil(2011,04,04))
      end

      describe "WITH having a 10 (working days) sprint and beeing 5 (working) days into it" do
        before(:each) do
          version.sprint_start_date = Date.today - 7.days
          version.effective_date = Date.today + 6.days
          version.save!
        end

        describe "WITH 1 story assigned to the sprint" do
          before(:each) do
            @story = Factory.create(:story, :subject => "Story 1",
                                            :project => project,
                                            :fixed_version => version,
                                            :tracker => tracker_feature,
                                            :status => issue_open,
                                            :priority => issue_priority,
                                            :created_on => Date.today - (20).days,
                                            :updated_on => Date.today - (20).days)
          end

          describe "WITH the story having a time_remaining defined on creation" do
            before(:each) do
              @story.update_attributes(:remaining_hours => 9)
            end

            describe "WITH updating time_remaining three days ago" do
              before(:each) do
                set_attribute_journalized @story, :remaining_hours=, 5, Time.now - 3.day

                @burndown = Burndown.new(sprint, project)
              end

              it { @burndown.remaining_hours.should eql [9.0, 9.0, 9.0, 9.0, 5.0, 5.0] }
              it { @burndown.remaining_hours.unit.should eql :hours }
              it { @burndown.days.should eql(sprint.days()) }
              it { @burndown.max[:hours].should eql 9.0 }
              it { @burndown.max[:points].should eql 0.0 }
              it { @burndown.remaining_hours_ideal.should eql [9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0] }

            end

            describe "WITH the story beeing moved out of the sprint within the sprint duration and also moved back in" do
              before(:each) do
                other_version = Factory.create(:version, :name => "other_version", :project => project)
                set_attribute_journalized @story, :fixed_version_id=, other_version.id, Time.now - 6.day
                set_attribute_journalized @story, :fixed_version_id=, version.id, Time.now - 3.day

                @burndown = Burndown.new(sprint, project)
              end

              it { @burndown.remaining_hours.should eql [9.0, 0.0, 0.0, 0.0, 9.0, 9.0] }
              it { @burndown.remaining_hours.unit.should eql :hours }
              it { @burndown.days.should eql(sprint.days()) }
              it { @burndown.max[:hours].should eql 9.0 }
              it { @burndown.max[:points].should eql 0.0 }
              it { @burndown.remaining_hours_ideal.should eql [9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0] }
            end
          end

        end

        describe "WITH 10 stories assigned to the sprint" do
          before(:each) do
            @stories = []

            (0..9).each do |i|
              @stories[i] = Factory.create(:story, :subject => "Story #{i}",
                                                   :project => project,
                                                   :fixed_version => version,
                                                   :tracker => tracker_feature,
                                                   :status => issue_open,
                                                   :priority => issue_priority,
                                                   :created_on => Date.today - (20 - i).days,
                                                   :updated_on => Date.today - (20 - i).days)
            end
          end

          describe "WITH each story having a time remaining defined at start" do
            before(:each) do
              @remaining_hours_sum = 0

              @stories.each_with_index do |s, i|
                set_attribute_journalized s, :remaining_hours=, 10, version.sprint_start_date - 3.days
              end
            end

            describe "WITH 5 stories having been reduced to 0 hours remaining, one story per day" do
              before(:each) do
                @finished_hours
                (0..4).each do |i|
                  set_attribute_journalized @stories[i], :remaining_hours=, 0, version.sprint_start_date + i.days + 1.hour
                end
              end

              describe "THEN" do
                before(:each) do
                  @burndown = Burndown.new(sprint, project)
                end

                it { @burndown.remaining_hours.should eql [90.0, 80.0, 70.0, 60.0, 50.0, 50.0] }
                it { @burndown.remaining_hours.unit.should eql :hours }
                it { @burndown.days.should eql(sprint.days()) }
                it { @burndown.max[:hours].should eql 90.0 }
                it { @burndown.max[:points].should eql 0.0 }
                it { @burndown.remaining_hours_ideal.should eql [90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0, 20.0, 10.0, 0.0] }
              end
            end
          end

          describe "WITH each story having story points defined at start" do
            before(:each) do
              @remaining_hours_sum = 0

              @stories.each_with_index do |s, i|
                set_attribute_journalized s, :story_points=, 10, version.sprint_start_date - 3.days
              end
            end

            describe "WITH 5 stories having been reduced to 0 story points, one story per day" do
              before(:each) do
                @finished_hours
                (0..4).each do |i|
                  set_attribute_journalized @stories[i], :story_points=, 0, version.sprint_start_date + i.days + 1.hour
                end
              end

              describe "THEN" do
                before(:each) do
                  @burndown = Burndown.new(sprint, project)
                end

                it { @burndown.story_points.should eql [90.0, 80.0, 70.0, 60.0, 50.0, 50.0] }
                it { @burndown.story_points.unit.should eql :points }
                it { @burndown.days.should eql(sprint.days()) }
                it { @burndown.max[:hours].should eql 0.0 }
                it { @burndown.max[:points].should eql 90.0 }
                it { @burndown.story_points_ideal.should eql [90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0, 20.0, 10.0, 0.0] }
              end
            end
          end

        end
      end
    end
  end
end