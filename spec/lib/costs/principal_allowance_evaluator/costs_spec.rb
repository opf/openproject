require File.dirname(__FILE__) + '/../../../spec_helper'

describe Costs::PrincipalAllowanceEvaluator::Costs do
  let(:klass) { Costs::PrincipalAllowanceEvaluator::Costs }
  let(:user) { Factory.build :user }
  let(:filter) { klass.new user }
  let(:member) { Factory.build :member }
  let(:project) { Factory.build :project }
  let(:role) { Factory.build :role }
  let(:role2) { Factory.build :role }
  let(:permission) { Redmine::AccessControl::Permission.new(:action, {}, {}) }
  let(:permission2) { Redmine::AccessControl::Permission.new(:action2, {}, {}) }

  before do
    @orig_permissions = Redmine::AccessControl.permissions.dup
    Redmine::AccessControl.permissions.clear
    Redmine::AccessControl.permissions << permission
    Redmine::AccessControl.permissions << permission2
  end

  after do
    Redmine::AccessControl.instance_variable_set("@permissions", @orig_permissions)
  end

  describe :granted_for_project? do
    describe "WHEN the role is allowing the action" do

      before do
        role.permissions << permission.name
      end

      it { filter.granted_for_project?(role, permission.name, project, {}).should be_true }
    end

    describe "WHEN the role is not allowing the action" do

      it { filter.granted_for_project?(role, permission.name, project, {}).should be_false }
    end
  end

  describe :granted_for_global? do
    describe "WHEN the membership has a role allowing the action" do

      before do
        member.roles = [role]

        role.permissions << permission.name
      end

      it { filter.granted_for_global?(member, permission.name, {}).should be_true }
    end

    describe "WHEN the membership has two roles
              WHEN the first role is not allowing the action
              WHEN the second role is not allowing the action
              WHEN the action is a granular_for an action the second role allows" do

      before do
        permission2.instance_variable_set("@granular_for", permission.name)

        member.user = user
        member.project = project
        member.roles = [role, role2]
        member.save!

        role2.permissions << permission2.name
        role2.save!
      end

      it { filter.granted_for_global?(member, permission.name, :for => user).should be_true }
    end

    describe "WHEN the membership has two roles
              WHEN the first role is not allowing the action
              WHEN the second role is not allowing the action
              WHEN the action is a granular_for an action the second role does not allow" do

      before do
        member.user = user
        member.project = project
        member.roles = [role, role2]
        member.save!

        role2.permissions << :action_non
        role2.save!
      end

      it { filter.granted_for_global?(member, permission.name, :for => user).should be_false }
    end

    describe "WHEN the membership has one role
              WHEN the role is allowing the action
              WHEN the action is a granular_for another action" do

      before do
        permission.instance_variable_set("@granular_for", :action_lorem)

        member.user = user
        member.project = project
        member.roles = [role]
        member.save!

        role.permissions << :action
        role.save!
      end

      it { filter.granted_for_global?(member, permission.name, {}).should be_true }
    end

    describe "WHEN inserting something other than a Member" do
      it { filter.granted_for_global?(1, :action, {}).should be_false }
    end
  end
end


