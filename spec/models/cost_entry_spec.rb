require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostEntry do

  before(:each) do
    User.current = users("admin")
    @example = cost_entries "example"
    Factory.create(:member, :project => @example.project,
                            :principal => @example.user,
                            :roles => [Factory.create(:role)])
  end

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :enumerations
  fixtures :enabled_modules
  fixtures :issue_statuses

  it "should always prefer overridden_costs" do
    value = rand(500)
    @example.overridden_costs = value
    @example.overridden_costs.should == value
    @example.real_costs.should == value
    @example.save!
  end

  it "should return the current costs depending on the number of units" do
    (0..100).each do |units|
      @example.units = units
      @example.save!
      @example.costs.should == @example.cost_type.rate_at(@example.spent_on).rate * units
    end
  end

  it "should update cost if a new rate is added at the end" do
    @example.cost_type = cost_types("umbrella")
    @example.spent_on = Time.now
    @example.units = 1
    @example.save!
    @example.costs.should == rates("cheap_one").rate
    (cheap = CostRate.new.tap do |cr|
      cr.valid_from = 1.day.ago
      cr.rate       = 1.0
      cr.cost_type  = cost_types("umbrella")
    end).save!
    @example.reload
    @example.rate.should_not == rates("cheap_one")
    @example.costs.should == cheap.rate
  end

  it "should update cost if a new rate is added in between" do
    @example.cost_type = cost_types("umbrella")
    @example.spent_on = 3.days.ago
    @example.units = 1
    @example.save!
    @example.costs.should == rates("cheap_three").rate
    (cheap = CostRate.new.tap do |cr|
      cr.valid_from = 3.days.ago.to_date
      cr.rate       = 1.0
      cr.cost_type  = cost_types("umbrella")
    end).save!
    @example.reload
    @example.rate.should_not == rates("cheap_three")
    @example.costs.should == cheap.rate
  end

  it "should update cost if a spent_on changes" do
    @example.units = 1
    (5.days.ago..Time.now).step(1.day) do |time|
      @example.spent_on = time
      @example.save!
      @example.costs.should == @example.cost_type.rate_at(time).rate
    end
  end

  it "should update cost if a rate is removed" do
    cheap_one = rates("cheap_one")
    @example.spent_on = rates("cheap_one").valid_from
    @example.units = 1
    @example.save!
    @example.costs.should == cheap_one.rate
    cheap_one.destroy
    @example.reload
    @example.costs.should == rates("cheap_three").rate
    rates("cheap_three").destroy
    @example.reload
    @example.costs.should == rates("cheap_five").rate
  end

  it "should be able to change order of rates (sorted by valid_from)" do
    cheap_one = rates("cheap_one")
    cheap_three = rates("cheap_three")
    @example.spent_on = cheap_one.valid_from
    @example.save!
    @example.rate.should == cheap_one
    cheap_one.valid_from = cheap_three.valid_from - 1.day
    cheap_one.save!
    @example.reload
    @example.rate.should == cheap_three
  end

  describe "fixtures free" do
    # TODO: rewrite fixture dependent tests towards using factories

    let(:project) { Factory.create(:project_with_trackers) }
    let(:project2) { Factory.create(:project_with_trackers) }
    let(:issue) { Factory.create(:issue, :project => project,
                                        :tracker => project.trackers.first,
                                        :author => user) }
    let(:issue2) { Factory.create(:issue, :project => project2,
                                         :tracker => project2.trackers.first,
                                         :author => user) }
    let(:user) { Factory.create(:user) }
    let(:user2) { Factory.create(:user) }
    let(:klass) { CostEntry }
    let(:cost_entry) { Factory.build(:cost_entry, :cost_type => cost_type,
                                                  :project => project,
                                                  :issue => issue,
                                                  :spent_on => date,
                                                  :units => units,
                                                  :user => user,
                                                  :comments => "lorem") }
    let(:cost_type) { Factory.create(:cost_type) }
    let(:member) { Factory.create(:member, :project => project,
                                           :roles => [role],
                                           :principal => user) }
    let(:role) { Factory.create(:role, :permissions => []) }
    let(:units) { 5.0 }
    let(:date) { Date.today }

    before do
      CostType.delete_all
      User.delete_all
      Project.delete_all
      Issue.delete_all
    end

    describe "instance" do
      describe "valid" do
        before do
          member.save!
          cost_entry.save!
        end

        it{ cost_entry.should be_valid }

        describe "WHEN no cost_type is provided" do
          before { cost_entry.cost_type = nil }

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN no project is provided" do
          before do
            cost_entry.project = nil
            # unfortunately the project get's set to the issue's project if no project is provided
            # TODO: check if that is necessary
            cost_entry.issue = nil
          end

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN no issue is provided" do
          before { cost_entry.issue = nil }

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN the issue is not in the project" do
          before { cost_entry.issue = issue2 }

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN no units are provided" do
          before { cost_entry.units = nil }

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN no spent_on is provided" do
          before { cost_entry.spent_on = nil }

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN no user is provided" do
          before { cost_entry.user = nil }

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN the provided user is no member of the project
                  WHEN the user is unchanged" do
          before { member.destroy }

          it { cost_entry.should be_valid }
        end

        describe "WHEN the provided user is no member of the project
                  WHEN the user changes" do
          before do
            cost_entry.user = user2
            member.destroy
          end

          it { cost_entry.should_not be_valid }
        end

        describe "WHEN the cost_type is deleted" do
          before { cost_type.deleted_at = Date.new }

          it { cost_entry.should_not be_valid }
    describe :user do
      describe "WHEN a non existing user is provided (i.e. the user has been deleted)" do
        before do
          cost_entry.save!
          user.destroy
        end

        it { cost_entry.reload.user.should == DeletedUser.first }
      end

      describe "WHEN an existing user is provided" do
        it { cost_entry.user.should == user }
      end
    end
  end
end
