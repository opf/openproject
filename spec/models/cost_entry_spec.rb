require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostEntry do

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
  let(:cost_entry) do
    member
    Factory.build(:cost_entry, :cost_type => cost_type,
                                                :project => project,
                                                :issue => issue,
                                                :spent_on => date,
                                                :units => units,
                                                :user => user,
                                                :comments => "lorem")
  end

  let(:cost_type) do
    cost_type = Factory.create(:cost_type)
    [first_rate, second_rate, third_rate].each do |rate|
      rate.cost_type = cost_type
      rate.save!
    end
    cost_type.reload
    cost_type
  end
  let(:first_rate) { Factory.build(:cost_rate, :valid_from => 6.days.ago,
                                               :rate => 10.0) }
  let(:second_rate) { Factory.build(:cost_rate, :valid_from => 4.days.ago,
                                                :rate => 100.0) }
  let(:third_rate) { Factory.build(:cost_rate, :valid_from => 2.days.ago,
                                               :rate => 1000.0) }
  let(:member) { Factory.create(:member, :project => project,
                                         :roles => [role],
                                         :principal => user) }
  let(:role) { Factory.create(:role, :permissions => []) }
  let(:units) { 5.0 }
  let(:date) { Date.today }

  describe "instance" do
    describe :costs do
      let(:fourth_rate) { Factory.build(:cost_rate, :valid_from => 1.days.ago,
                                                    :rate => 10000.0,
                                                    :cost_type => cost_type) }

      describe "WHEN updating the number of units" do
        before do
          cost_entry.spent_on = first_rate.valid_from + 1.day
        end

        it "should update costs" do
          (0..5).each do |units|
            cost_entry.units = units
            cost_entry.save!
            cost_entry.costs.should == first_rate.rate * units
          end
        end
      end

      describe "WHEN a new rate is added at the end" do
        before do
          cost_entry.save!
          fourth_rate.save!
          cost_entry.reload
        end

        it { cost_entry.costs.should == fourth_rate.rate * cost_entry.units }
      end

      describe "WHEN a new rate is added for the future" do
        before do
          cost_entry.save!
          fourth_rate.valid_from = 1.day.from_now
          fourth_rate.save!
          cost_entry.reload
        end

        it { cost_entry.costs.should == third_rate.rate * cost_entry.units }
      end

      describe "WHEN a new rate is added in between" do
        before do
          cost_entry.save!
          fourth_rate.valid_from = 3.days.ago
          fourth_rate.save!
          cost_entry.reload
        end

        it { cost_entry.costs.should == third_rate.rate * cost_entry.units }
      end

      describe "WHEN a rate is destroyed" do
        before do
          cost_entry.save!
          third_rate.destroy
          cost_entry.reload
        end

        it { cost_entry.costs.should == cost_entry.units * second_rate.rate }
      end

      describe "WHEN a rate's valid from is updated" do
        before do
          cost_entry.save!
          first_rate.update_attribute(:valid_from, 1.days.ago)
          cost_entry.reload
        end

        it { cost_entry.costs.should == cost_entry.units * first_rate.rate }
      end

      describe "WHEN spent on is changed" do
        before do
          cost_type.save!
          cost_entry.save!
        end

        it "should take the then active rate to calculate" do
          (5.days.ago..Time.now).step(1.day) do |time|
            cost_entry.spent_on = time
            cost_entry.save!
            cost_entry.costs.should == cost_entry.units * CostRate.first(:conditions => ["cost_type_id = ? AND valid_from <= ?", cost_entry.cost_type.id, cost_entry.spent_on], :order => "valid_from DESC").rate
          end
        end
      end
    end

    describe :overridden_costs do
      describe "WHEN overridden costs are seet" do
        let(:value) { rand(500) }

        before do
          cost_entry.overridden_costs = value
        end

        it { cost_entry.overridden_costs.should == value }
      end
    end

    describe :real_costs do
      describe "WHEN overrridden cost are set" do
        let(:value) { rand(500) }

        before do
          cost_entry.overridden_costs = value
        end

        it { cost_entry.real_costs.should == value }
      end
    end

    describe :valid do
      before do
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
      end
    end

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
