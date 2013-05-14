require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  include Cost::PluginSpecHelper
  let(:klass) { User }
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.build(:valid_project) }
  let(:project2) { FactoryGirl.build(:valid_project) }

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
        user.allowed_to_condition_with_project_id(permission).should == "(projects.id in (#{project.id}, #{project2.id}))"
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
end
