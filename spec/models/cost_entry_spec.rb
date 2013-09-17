require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostEntry do
  include Cost::PluginSpecHelper

  let(:project) { FactoryGirl.create(:project_with_trackers) }
  let(:project2) { FactoryGirl.create(:project_with_trackers) }
  let(:work_package) { FactoryGirl.create(:work_package, :project => project,
                                       :tracker => project.trackers.first,
                                       :author => user) }
  let(:work_package2) { FactoryGirl.create(:work_package, :project => project2,
                                        :tracker => project2.trackers.first,
                                        :author => user) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:klass) { CostEntry }
  let(:cost_entry) do
    member
    FactoryGirl.build(:cost_entry, :cost_type => cost_type,
                               :project => project,
                               :work_package => work_package,
                               :spent_on => date,
                               :units => units,
                               :user => user,
                               :comments => "lorem")
  end

  let(:cost_entry2) do
    FactoryGirl.build(:cost_entry, :cost_type => cost_type,
                               :project => project,
                               :work_package => work_package,
                               :spent_on => date,
                               :units => units,
                               :user => user,
                               :comments => "lorem")
  end

  let(:cost_type) do
    cost_type = FactoryGirl.create(:cost_type)
    [first_rate, second_rate, third_rate].each do |rate|
      rate.cost_type = cost_type
      rate.save!
    end
    cost_type.reload
    cost_type
  end
  let(:first_rate) { FactoryGirl.build(:cost_rate, :valid_from => 6.days.ago,
                                               :rate => 10.0) }
  let(:second_rate) { FactoryGirl.build(:cost_rate, :valid_from => 4.days.ago,
                                                :rate => 100.0) }
  let(:third_rate) { FactoryGirl.build(:cost_rate, :valid_from => 2.days.ago,
                                               :rate => 1000.0) }
  let(:member) { FactoryGirl.create(:member, :project => project,
                                         :roles => [role],
                                         :principal => user) }
  let(:role) { FactoryGirl.create(:role, :permissions => []) }
  let(:units) { 5.0 }
  let(:date) { Date.today }

  describe "class" do
    describe :visible do
      describe "WHEN having the view_cost_entries permission
                WHEN querying for a project
                WHEN a cost entry from another user is defined" do
        before do
          is_member(project, user2, [:view_cost_entries])

          cost_entry.save!
        end

        it { CostEntry.visible(user2, project).all.should =~ [cost_entry] }
      end

      describe "WHEN not having the view_cost_entries permission
                WHEN querying for a project
                WHEN a cost entry from another user is defined" do
        before do
          is_member(project, user2, [])

          cost_entry.save!
        end

        it { CostEntry.visible(user2, project).all.should =~ [] }
      end

      describe "WHEN having the view_own_cost_entries permission
                WHEN querying for a project
                WHEN a cost entry from another user is defined" do
        before do
          is_member(project, user2, [:view_own_cost_entries])

          cost_entry.save!
        end

        it { CostEntry.visible(user2, project).all.should =~ [] }
      end

      describe "WHEN having the view_own_cost_entries permission
                WHEN querying for a project
                WHEN a cost entry from the user is defined" do
        before do
          is_member(project, cost_entry2.user, [:view_own_cost_entries])

          cost_entry2.save!
        end

        it { CostEntry.visible(cost_entry2.user, project).all.should =~ [cost_entry2] }
      end
    end
  end

  describe "instance" do
    describe :costs do
      let(:fourth_rate) { FactoryGirl.build(:cost_rate, :valid_from => 1.days.ago,
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
          (5.days.ago.to_date..Date.today).each do |time|
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
          # unfortunately the project get's set to the work_package's project if no project is provided
          # TODO: check if that is necessary
          cost_entry.work_package = nil
        end

        it { cost_entry.should_not be_valid }
      end

      describe "WHEN no work_package is provided" do
        before { cost_entry.work_package = nil }

        it { cost_entry.should_not be_valid }
      end

      describe "WHEN the work_package is not in the project" do
        before { cost_entry.work_package = work_package2 }

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

    describe :editable_by? do
      describe "WHEN the user has the edit_cost_entries permission
                WHEN the cost entry is not created by the user" do
        before do
          is_member(project, user2, [:edit_cost_entries])

          cost_entry
        end

        it { cost_entry.editable_by?(user2).should be_true }
      end

      describe "WHEN the user has the edit_cost_entries permission
                WHEN the cost entry is created by the user" do
        before do
          is_member(project, cost_entry2.user, [:edit_cost_entries])
        end

        it { cost_entry2.editable_by?(cost_entry2.user).should be_true }
      end

      describe "WHEN the user has the edit_own_cost_entries permission
                WHEN the cost entry is created by the user" do
        before do
          is_member(project, cost_entry2.user, [:edit_own_cost_entries])

          cost_entry2
        end

        it { cost_entry2.editable_by?(cost_entry2.user).should be_true }
      end

      describe "WHEN the user has the edit_own_cost_entries permission
                WHEN the cost entry is created by another user" do
        before do
          is_member(project, user2, [:edit_own_cost_entries])

          cost_entry
        end

        it { cost_entry.editable_by?(user2).should be_false }
      end

      describe "WHEN the user has no cost permission
                WHEN the cost entry is created by the user" do
        before do
          is_member(project, cost_entry2.user, [])

          cost_entry2
        end

        it { cost_entry2.editable_by?(cost_entry2.user).should be_false }
      end
    end

    describe :creatable_by? do
      describe "WHEN the user has the log costs permission
                WHEN the cost entry is not associated to the user" do
        before do
          is_member(project, user2, [:log_costs])
        end

        it { cost_entry.creatable_by?(user2).should be_true }
      end

      describe "WHEN the user has the log_costs permission
                WHEN the cost entry is associated to user" do
        before do
          is_member(project, cost_entry2.user, [:log_costs])
        end

        it { cost_entry2.creatable_by?(cost_entry2.user).should be_true }
      end

      describe "WHEN the user has the log own costs permission
                WHEN the cost entry is associated to the user" do
        before do
          is_member(project, cost_entry2.user, [:log_own_costs])
        end

        it { cost_entry2.creatable_by?(cost_entry2.user).should be_true }
      end

      describe "WHEN the user has the log_own_costs permission
                WHEN the cost entry is created by another user" do
        before do
          is_member(project, user2, [:log_own_costs])
        end

        it { cost_entry.creatable_by?(user2).should be_false }
      end

      describe "WHEN the user has no cost permission
                WHEN the cost entry is associated to the user" do
        before do
          is_member(project, cost_entry2.user, [])
        end

        it { cost_entry2.creatable_by?(cost_entry2.user).should be_false }
      end
    end

    describe :costs_visible_by? do
      describe "WHEN the user has the view_cost_rates permission
                WHEN the cost entry is not associated to the user" do
        before do
          is_member(project, user2, [:view_cost_rates])
        end

        it { cost_entry.costs_visible_by?(user2).should be_true }
      end

      describe "WHEN the user has the view_cost_rates permission in another project
                WHEN the cost entry is not associated to the user" do
        before do
          is_member(project2, user2, [:view_cost_rates])
        end

        it { cost_entry.costs_visible_by?(user2).should be_false }
      end

      describe "WHEN the user lacks the view_cost_rates permission
                WHEN the cost entry is associated to the user
                WHEN the costs are overridden" do
        before do
          is_member(project, cost_entry2.user, [])
          cost_entry2.update_attribute(:overridden_costs, 1.0)
        end

        it { cost_entry2.costs_visible_by?(cost_entry2.user).should be_true }
      end

      describe "WHEN the user lacks the view_cost_rates permission
                WHEN the cost entry is associated to the user
                WHEN the costs are not overridden" do
        before do
          is_member(project, cost_entry2.user, [])
        end

        it { cost_entry2.costs_visible_by?(cost_entry2.user).should be_false }
      end
    end
  end
end
