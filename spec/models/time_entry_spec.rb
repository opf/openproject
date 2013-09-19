require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TimeEntry do
  include Cost::PluginSpecHelper
  let(:project) { FactoryGirl.create(:project_with_types, is_public: false) }
  let(:project2) { FactoryGirl.create(:project_with_types, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, :project => project,
                                       :type => project.types.first,
                                       :author => user) }
  let(:work_package2) { FactoryGirl.create(:work_package, :project => project2,
                                       :type => project2.types.first,
                                       :author => user2) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:date) { Date.today }
  let(:rate) { FactoryGirl.build(:cost_rate) }
  let!(:hourly_one) { FactoryGirl.create(:hourly_rate, valid_from: 2.days.ago, project: project, user: user) }
  let!(:hourly_three) { FactoryGirl.create(:hourly_rate, valid_from: 4.days.ago, project: project, user: user) }
  let!(:hourly_five) { FactoryGirl.create(:hourly_rate, valid_from: 6.days.ago, project: project, user: user) }
  let!(:default_hourly_one) { FactoryGirl.create(:default_hourly_rate, valid_from: 2.days.ago, project: project, user: user2) }
  let!(:default_hourly_three) { FactoryGirl.create(:default_hourly_rate, valid_from: 4.days.ago, project: project, user: user2) }
  let!(:default_hourly_five) { FactoryGirl.create(:default_hourly_rate, valid_from: 6.days.ago, project: project, user: user2) }
  let(:hours) { 5.0 }
  let(:time_entry) do
    FactoryGirl.create(:time_entry, :project => project,
                               :work_package => work_package,
                               :spent_on => date,
                               :hours => hours,
                               :user => user,
                               :rate => hourly_one,
                               :comments => "lorem")
  end

  let(:time_entry2) do
    FactoryGirl.create(:time_entry, :project => project,
                               :work_package => work_package,
                               :spent_on => date,
                               :hours => hours,
                               :user => user,
                               :rate => hourly_one,
                               :comments => "lorem")
  end


  it "should always prefer overridden_costs" do
    User.stub!(:current).and_return(user)

    value = rand(500)
    time_entry.overridden_costs = value
    time_entry.overridden_costs.should == value
    time_entry.real_costs.should == value
    time_entry.save!
  end

  describe "given rate" do
    before(:each) do
      User.stub!(:current).and_return(user)
      @default_example = time_entry2
    end

    it "should return the current costs depending on the number of hours" do
      (0..100).each do |hours|
        time_entry.hours = hours
        time_entry.save!
        time_entry.costs.should == time_entry.rate.rate * hours
      end
    end

    it "should update cost if a new rate is added at the end" do
      time_entry.user = User.current
      time_entry.spent_on = Time.now
      time_entry.hours = 1
      time_entry.save!
      time_entry.costs.should == hourly_one.rate
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 1.day.ago
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = hourly_one.project
      end).save!
      time_entry.reload
      time_entry.rate.should_not == hourly_one
      time_entry.costs.should == hourly.rate
    end

    it "should update cost if a new rate is added in between" do
      time_entry.user = User.current
      time_entry.spent_on = 3.days.ago.to_date
      time_entry.hours = 1
      time_entry.save!
      time_entry.costs.should == hourly_three.rate
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 3.days.ago.to_date
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = hourly_one.project
      end).save!
      time_entry.reload
      time_entry.rate.should_not == hourly_three
      time_entry.costs.should == hourly.rate
    end

    it "should update cost if a spent_on changes" do
      time_entry.hours = 1
      (5.days.ago.to_date..Date.today).each do |time|
        time_entry.spent_on = time.to_date
        time_entry.save!
        time_entry.costs.should == time_entry.user.rate_at(time, project.id).rate
      end
    end

    it "should update cost if a rate is removed" do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.hours = 1
      time_entry.save!
      time_entry.costs.should == hourly_one.rate
      hourly_one.destroy
      time_entry.reload
      time_entry.costs.should == hourly_three.rate
      hourly_three.destroy
      time_entry.reload
      time_entry.costs.should == hourly_five.rate
    end

    it "should be able to change order of rates (sorted by valid_from)" do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.save!
      time_entry.rate.should == hourly_one
      hourly_one.valid_from = hourly_three.valid_from - 1.day
      hourly_one.save!
      time_entry.reload
      time_entry.rate.should == hourly_three
    end

  end

  describe "default rate" do
    before(:each) do
      User.stub!(:current).and_return(user)
      @default_example = time_entry2
    end

    it "should return the current costs depending on the number of hours" do
      (0..100).each do |hours|
        @default_example.hours = hours
        @default_example.save!
        @default_example.costs.should == @default_example.rate.rate * hours
      end
    end

    it "should update cost if a new rate is added at the end" do
      @default_example.user = user2
      @default_example.spent_on = Time.now.to_date
      @default_example.hours = 1
      @default_example.save!
      @default_example.costs.should == default_hourly_one.rate
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 1.day.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = user2
      end).save!
      @default_example.reload
      @default_example.rate.should_not == default_hourly_one
      @default_example.costs.should == hourly.rate
    end

    it "should update cost if a new rate is added in between" do
      @default_example.user = user2
      @default_example.spent_on = 3.days.ago.to_date
      @default_example.hours = 1
      @default_example.save!
      @default_example.costs.should == default_hourly_three.rate
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 3.days.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = user2
      end).save!
      @default_example.reload
      @default_example.rate.should_not == default_hourly_three
      @default_example.costs.should == hourly.rate
    end

    it "should update cost if a spent_on changes" do
      @default_example.hours = 1
      (5.days.ago.to_date..Date.today).each do |time|
        @default_example.spent_on = time.to_date
        @default_example.save!
        @default_example.costs.should == @default_example.user.rate_at(time, project.id).rate
      end
    end

    it "should update cost if a rate is removed" do
      @default_example.spent_on = default_hourly_one.valid_from
      @default_example.hours = 1
      @default_example.save!
      @default_example.costs.should == default_hourly_one.rate
      default_hourly_one.destroy
      @default_example.reload
      @default_example.costs.should == default_hourly_three.rate
      default_hourly_three.destroy
      @default_example.reload
      @default_example.costs.should == default_hourly_five.rate
    end

    it "shoud be able to switch between default hourly rate and hourly rate" do
      @default_example.user = user2
      @default_example.rate = default_hourly_one
      @default_example.save!
      @default_example.reload
      @default_example.rate.should == default_hourly_one

      (rate = HourlyRate.new.tap do |hr|
        hr.valid_from = 10.days.ago.to_date
        hr.rate       = 1337.0
        hr.user       = @default_example.user
        hr.project    = project
      end).save!

      @default_example.reload
      @default_example.rate.should == rate
      rate.destroy
      @default_example.reload
      @default_example.rate.should == default_hourly_one
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
