require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TimeEntry do
  include Cost::PluginSpecHelper
  let(:project) { FactoryGirl.create(:project_with_trackers) }
  let(:project2) { FactoryGirl.create(:project_with_trackers) }
  let(:issue) { FactoryGirl.create(:issue, :project => project,
                                       :tracker => project.trackers.first,
                                       :author => user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:time_entry) do
    FactoryGirl.build(:time_entry, :project => project,
                               :issue => issue,
                               :spent_on => date,
                               :hours => hours,
                               :user => user,
                               :activity => activity,
                               :rate => rate,
                               :comments => "lorem")
  end

  let(:time_entry2) do
    FactoryGirl.build(:time_entry, :project => project,
                               :issue => issue,
                               :spent_on => date,
                               :hours => hours,
                               :user => user,
                               :activity => activity,
                               :rate => rate,
                               :comments => "lorem")
  end
  let(:date) { Date.today }
  let(:activity) { FactoryGirl.build(:time_entry_activity) }
  let(:rate) { FactoryGirl.build(:cost_rate) }
  let(:hours) { 5.0 }

  before(:each) do
    User.current = users("admin")
    @example = time_entries "example"
    @default_example = time_entries "default_example"
  end

  fixtures :users
  fixtures :time_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :enumerations
  fixtures :issue_statuses

  it "should always prefer overridden_costs" do
    value = rand(500)
    @example.overridden_costs = value
    @example.overridden_costs.should == value
    @example.real_costs.should == value
    @example.save!
  end

  describe "given rate" do

    it "should return the current costs depending on the number of hours" do
      (0..100).each do |hours|
        @example.hours = hours
        @example.save!
        @example.costs.should == @example.rate.rate * hours
      end
    end

    it "should update cost if a new rate is added at the end" do
      @example.user = User.current
      @example.spent_on = Time.now
      @example.hours = 1
      @example.save!
      @example.costs.should == rates("hourly_one").rate
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 1.day.ago
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = rates("hourly_one").project
      end).save!
      @example.reload
      @example.rate.should_not == rates("hourly_one")
      @example.costs.should == hourly.rate
    end

    it "should update cost if a new rate is added in between" do
      @example.user = User.current
      @example.spent_on = 3.days.ago.to_date
      @example.hours = 1
      @example.save!
      @example.costs.should == rates("hourly_three").rate
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 3.days.ago.to_date
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = rates("hourly_one").project
      end).save!
      @example.reload
      @example.rate.should_not == rates("hourly_three")
      @example.costs.should == hourly.rate
    end

    it "should update cost if a spent_on changes" do
      @example.hours = 1
      (5.days.ago..Time.now).step(1.day) do |time|
        @example.spent_on = time.to_date
        @example.save!
        @example.costs.should == @example.user.rate_at(time, 1).rate
      end
    end

    it "should update cost if a rate is removed" do
      hourly_one = rates("hourly_one")
      @example.spent_on = hourly_one.valid_from
      @example.hours = 1
      @example.save!
      @example.costs.should == hourly_one.rate
      hourly_one.destroy
      @example.reload
      @example.costs.should == rates("hourly_three").rate
      rates("hourly_three").destroy
      @example.reload
      @example.costs.should == rates("hourly_five").rate
    end

    it "should be able to change order of rates (sorted by valid_from)" do
      hourly_one = rates("hourly_one")
      hourly_three = rates("hourly_three")
      @example.spent_on = hourly_one.valid_from
      @example.save!
      @example.rate.should == hourly_one
      hourly_one.valid_from = hourly_three.valid_from - 1.day
      hourly_one.save!
      @example.reload
      @example.rate.should == hourly_three
    end

  end

  describe "default rate" do

    it "should return the current costs depending on the number of hours" do
      (0..100).each do |hours|
        @default_example.hours = hours
        @default_example.save!
        @default_example.costs.should == @default_example.rate.rate * hours
      end
    end

    it "should update cost if a new rate is added at the end" do
      @default_example.user = users("john")
      @default_example.spent_on = Time.now.to_date
      @default_example.hours = 1
      @default_example.save!
      @default_example.costs.should == rates("default_hourly_one").rate
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 1.day.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = users("john")
      end).save!
      @default_example.reload
      @default_example.rate.should_not == rates("default_hourly_one")
      @default_example.costs.should == hourly.rate
    end

    it "should update cost if a new rate is added in between" do
      @default_example.user = users("john")
      @default_example.spent_on = 3.days.ago.to_date
      @default_example.hours = 1
      @default_example.save!
      @default_example.costs.should == rates("default_hourly_three").rate
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 3.days.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = users("john")
      end).save!
      @default_example.reload
      @default_example.rate.should_not == rates("default_hourly_three")
      @default_example.costs.should == hourly.rate
    end

    it "should update cost if a spent_on changes" do
      @default_example.hours = 1
      (5.days.ago..Time.now).step(1.day) do |time|
        @default_example.spent_on = time.to_date
        @default_example.save!
        @default_example.costs.should == @default_example.user.rate_at(time, 1).rate
      end
    end

    it "should update cost if a rate is removed" do
      default_hourly_one = rates("default_hourly_one")
      @default_example.spent_on = default_hourly_one.valid_from
      @default_example.hours = 1
      @default_example.save!
      @default_example.costs.should == default_hourly_one.rate
      default_hourly_one.destroy
      @default_example.reload
      @default_example.costs.should == rates("default_hourly_three").rate
      rates("default_hourly_three").destroy
      @default_example.reload
      @default_example.costs.should == rates("default_hourly_five").rate
    end

    it "shoud be able to switch between default hourly rate and hourly rate" do
      user = users("john")
      @default_example.rate.should == rates("default_hourly_one")
      (rate = HourlyRate.new.tap do |hr|
        hr.valid_from = 10.days.ago.to_date
        hr.rate       = 1337.0
        hr.user       = user
        hr.project    = rates("hourly_one").project
      end).save!
      @default_example.reload
      @default_example.rate.should == rate
      rate.destroy
      @default_example.reload
      @default_example.rate.should == rates("default_hourly_one")
    end

    describe :costs_visible_by? do
      before do
        project.enabled_module_names = project.enabled_module_names << "costs_module"
      end

      describe "WHEN the time_entry is assigned to the user
                WHEN the user has the view_own_hourly_rate permission" do

        before do
          is_member(project, user, [:view_own_hourly_rate])

          time_entry.user = user
        end

        it { time_entry.costs_visible_by?(user).should be_true }
      end

      describe "WHEN the time_entry is assigned to the user
                WHEN the user lacks permissions" do

        before do
          is_member(project, user, [])

          time_entry.user = user
        end

        it { time_entry.costs_visible_by?(user).should be_false }
      end

      describe "WHEN the time_entry is assigned to another user
                WHEN the user has the view_hourly_rates permission" do

        before do
          is_member(project, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { time_entry.costs_visible_by?(user2).should be_true }
      end

      describe "WHEN the time_entry is assigned to another user
                WHEN the user has the view_hourly_rates permission in another project" do

        before do
          is_member(project2, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { time_entry.costs_visible_by?(user2).should be_false }
      end
    end
  end

  describe "class" do
    describe :visible do
      describe "WHEN having the view_time_entries permission
                WHEN querying for a project
                WHEN a time entry from another user is defined" do
        before do
          is_member(project, user2, [:view_time_entries])

          time_entry.save!
        end

        it { TimeEntry.visible(user2, project).all.should =~ [time_entry] }
      end

      describe "WHEN not having the view_time_entries permission
                WHEN querying for a project
                WHEN a time entry from another user is defined" do
        before do
          is_member(project, user2, [])

          time_entry.save!
        end

        it { TimeEntry.visible(user2, project).all.should =~ [] }
      end

      describe "WHEN having the view_own_time_entries permission
                WHEN querying for a project
                WHEN a time entry from another user is defined" do
        before do
          is_member(project, user2, [:view_own_time_entries])
          # don't understand why memberships get loaded on the user
          time_entry2.user.memberships(true)

          time_entry.save!
        end

        it { TimeEntry.visible(user2, project).all.should =~ [] }
      end

      describe "WHEN having the view_own_time_entries permission
                WHEN querying for a project
                WHEN a time entry from the user is defined" do
        before do
          is_member(project, time_entry2.user, [:view_own_time_entries])
          # don't understand why memberships get loaded on the user
          time_entry2.user.memberships(true)

          time_entry2.save!
        end

        it { TimeEntry.visible(time_entry2.user, project).all.should =~ [time_entry2] }
      end
    end
  end
end
