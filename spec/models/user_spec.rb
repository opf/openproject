require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  include Cost::PluginSpecHelper
  let(:klass) { User }
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.build(:valid_project) }
  let(:project2) { FactoryGirl.build(:valid_project) }
  let(:project_hourly_rate) { FactoryGirl.build(:hourly_rate, :user => user,
                                                              :project => project) }
  let(:default_hourly_rate) { FactoryGirl.build(:default_hourly_rate, :user => user) }

  describe :allowed_to do
    describe "WITH querying for a non existent permission" do
      it { user.allowed_to?(:bogus_permission, project).should be_false }
    end
  end

  describe :allowed_to_condition_with_project_id do
    let(:permission) { :view_own_time_entries }

    before do
      project.save!
      project2.save!
    end

    describe "WHEN user has the permission in one project
              WHEN not requesting for a specific project" do
      before do

        is_member(project, user, [permission])
      end

      it "should return a sql condition where the project id the user has the permission in is enforced" do
        user.allowed_to_condition_with_project_id(permission).should == "(projects.id in (#{project.id}))"
      end
    end

    describe "WHEN user has the permission in two projects
              WHEN not requesting for a specific project" do
      before do
        is_member(project, user, [permission])
        is_member(project2, user, [permission])
      end

      it "should return a sql condition where all the project ids the user has the permission in is enforced" do
        # as order is not guaranteed and in fact does not matter
        # we have to check for both valid options
        valid_conditions = ["(projects.id in (#{project.id}, #{project2.id}))",
                            "(projects.id in (#{project2.id}, #{project.id}))"]

        valid_conditions.should include(user.allowed_to_condition_with_project_id(permission))
      end
    end

    describe "WHEN user does not have the permission in any
              WHEN not requesting for a specific project" do
      before do
        user.save!
      end

      it "should return a neutral (for an or operation) sql condition" do
        user.allowed_to_condition_with_project_id(permission).should == "1=0"
      end
    end

    describe "WHEN user has the permission in two projects
              WHEN requesting for a specific project" do
      before do
        is_member(project, user, [permission])
        is_member(project2, user, [permission])
      end

      it "should return a sql condition where all the project ids the user has the permission in is enforced" do
        user.allowed_to_condition_with_project_id(permission, project).should == "(projects.id in (#{project.id}))"
      end
    end
  end

  describe :set_existing_rates do
    before do
      user.save
      project.save
    end

    describe "WHEN providing a project
              WHEN providing attributes for an existing rate in the project" do

      let(:new_attributes) { { project_hourly_rate.id.to_s => { :valid_from => (Date.today + 1.day).to_s,
                                                                :rate => (project_hourly_rate.rate + 5).to_s } } }

      before do
        project_hourly_rate.save!
        user.rates(true)

        user.set_existing_rates(project, new_attributes)
      end

      it "should update the rate" do
        user.rates.detect{ |r| r.id == project_hourly_rate.id }.rate.should == new_attributes[project_hourly_rate.id.to_s][:rate].to_i
      end

      it "should update valid_from" do
        user.rates.detect{ |r| r.id == project_hourly_rate.id }.valid_from.should == new_attributes[project_hourly_rate.id.to_s][:valid_from].to_date
      end

      it "should not create a rate" do
        user.rates.size.should == 1
      end
    end

    describe "WHEN providing a project
              WHEN providing attributes for an existing rate in another project" do

      let(:new_attributes) { { project_hourly_rate.id.to_s => { :valid_from => (Date.today + 1.day).to_s,
                                                                :rate => (project_hourly_rate.rate + 5).to_s } } }

      before do
        project_hourly_rate.save!
        user.rates(true)
        @original_rate = project_hourly_rate.rate
        @original_valid_from = project_hourly_rate.valid_from

        user.set_existing_rates(project2, new_attributes)
      end

      it "should not update the rate" do
        user.rates.detect{ |r| r.id == project_hourly_rate.id }.rate.should == @original_rate
      end

      it "should not update valid_from" do
        user.rates.detect{ |r| r.id == project_hourly_rate.id }.valid_from.should == @original_valid_from
      end

      it "should not create a rate" do
        user.rates.size.should == 1
      end
    end

    describe "WHEN providing a project
              WHEN not providing attributes" do

      before do
        project_hourly_rate.save!
        user.rates(true)

        user.set_existing_rates(project, {})
      end

      it "should delete the hourly rate" do
        user.rates(true).should be_empty
      end
    end

    describe "WHEN not providing a project
              WHEN not providing attributes" do

      before do
        default_hourly_rate.save!
        user.default_rates(true)

        user.set_existing_rates(nil, {})
      end

      it "should delete the default hourly rate" do
        user.default_rates(true).should be_empty
      end
    end
  end
end
