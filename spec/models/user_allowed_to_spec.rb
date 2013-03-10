require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe User, "#allowed_to?" do
  let(:member) { Factory.build(:member) }
  let(:member2) { Factory.build(:member) }
  let(:group_member) { Factory.build(:member) }

  let(:role) { Factory.build(:role) }
  let(:role2) { Factory.build(:role) }
  let(:user) { Factory.build(:user) }

  let(:non_member) { Factory.build(:non_member) }
  let(:anonymous_role) { Factory.build(:anonymous_role) }

  let(:permission) { Redmine::AccessControl::Permission.new(:action, {}, {}) }
  let(:permission2) { Redmine::AccessControl::Permission.new(:action2, {}, {}) }
  let(:project) { Factory.build(:project) }
  let(:project2) { Factory.build(:project) }
  let(:group) { Group.new :lastname => "group" }

#  def create_member_with_roles roles
#    member.user = user
#    member.project = project
#    member.roles = roles
#    member.save!
#    member
#  end
#
#  before do
#    project.save!
#    @orig_permissions = Redmine::AccessControl.permissions.dup
#    Redmine::AccessControl.permissions.clear
#    Redmine::AccessControl.permissions << permission
#    Redmine::AccessControl.permissions << permission2
#
#    non_member.save!
#    anonymous_role.save!
#    User.anonymous
#    user.save!
#    role.save!
#  end
#
#  after do
#    User.destroy_all
#    Redmine::AccessControl.instance_variable_set("@permissions", @orig_permissions)
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has a role allowing the action" do
#    before do
#      create_member_with_roles [role]
#
#      role.permissions << permission.name
#      role.save
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_true }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has a role not allowing the action" do
#    before do
#      create_member_with_roles [role]
#
#      role.permissions << :action_non
#      role.save
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_false }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has a role not allowing the action
#            WHEN the membership has a second role allowing the action" do
#    before do
#      create_member_with_roles [role, role2]
#
#      role.permissions << :action_non
#      role.save!
#      role2.permissions << permission.name
#      role2.save!
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_true }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has two roles
#            WHEN the first role is not allowing the action
#            WHEN the second role is not allowing the action
#            WHEN the action is a granular_for an action the second role allows" do
#
#    before do
#      permission2.instance_variable_set("@granular_for_obj", permission)
#
#      create_member_with_roles [role, role2]
#
#      role2.permissions << permission2.name
#      role2.save!
#    end
#
#    it { user.allowed_to?(permission.name, project).should be_true }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has two roles
#            WHEN the first role is not allowing the action
#            WHEN the second role is not allowing the action
#            WHEN the action is a granular_for an action the second role does not allow" do
#
#    before do
#      permission2.instance_variable_set("@granular_for_obj", permission)
#
#      create_member_with_roles [role, role2]
#
#      role2.permissions << :non
#      role2.save!
#    end
#
#    it { user.allowed_to?(permission.name, project).should be_false }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has one role
#            WHEN the first role is allowing the action
#            WHEN the action is a granular_for another action
#            WHEN the request is issued for the user" do
#
#    before do
#      permission.instance_variable_set("@granular_for_obj", permission2)
#
#      create_member_with_roles [role]
#
#      role.permissions << :action
#      role.save!
#    end
#
#    it { user.allowed_to?(permission.name, project, :for => user).should be_true }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user has a membership in the project
#            WHEN the membership has one role
#            WHEN the first role is allowing the action
#            WHEN the action is a granular_for another action
#            WHEN the request is issued for somebody else" do
#
#    before do
#      permission.instance_variable_set("@granular_for_obj", permission2)
#
#      create_member_with_roles [role]
#
#      role.permissions << :action
#      role.save!
#    end
#
#    it { user.allowed_to?(permission.name, project, :for => Factory.build(:user)).should be_false }
#  end
#
#
#  describe "WHEN requesting a project permission
#            WHEN the user has no membership in this project" do
#    before do
#      member.user = user
#      member.project = Factory.build(:project)
#      member.roles = [role]
#      member.save!
#
#      role.permissions << permission.name
#      role.save!
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_false }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the user is admin" do
#    before do
#      user.admin = true
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_true }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the project is public
#            WHEN the action is allowed for non members" do
#    before do
#      project.is_public = true
#
#      non_member.permissions << permission.name
#      non_member.save!
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_true }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the project is public
#            WHEN the action is not allowed for non members" do
#    before do
#      project.is_public = true
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_false }
#  end
#
#  describe "WHEN requesting a project permission as anonymous
#            WHEN the project is public
#            WHEN the action is allowed for anonymous" do
#    before do
#      project.is_public = true
#
#      anonymous_role.permissions << permission.name
#      anonymous_role.save!
#    end
#
#    it { User.anonymous.allowed_to?(permission.name, project, {}).should be_true }
#  end
#
#  describe "WHEN requesting a project permission as anonymous
#            WHEN the project is public
#            WHEN the action is not allowed for anonymous" do
#    before do
#      project.is_public = true
#    end
#
#    it { User.anonymous.allowed_to?(permission.name, project, {}).should be_false }
#  end
#
#
#  describe "WHEN requesting a project permission
#            WHEN the project is inactive" do
#    before do
#      create_member_with_roles [role]
#
#      role.permissions << permission.name
#
#      project.archive
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_false }
#  end
#
#  describe "WHEN requesting a project permission
#            WHEN the project is not allowing the action" do
#    before do
#      create_member_with_roles [role]
#
#      project.instance_variable_set("@allowed_permissions", [])
#
#      role.permissions << permission.name
#
#      role.save!
#    end
#
#    it { user.allowed_to?(permission.name, project, {}).should be_false }
#  end
#
#  describe "WHEN requesting a permission on two projects
#            WHEN the permission is granted on both projects" do
#    before do
#      project2.save!
#
#      create_member_with_roles [role]
#
#      member2.project = project2
#      member2.user = user
#      member2.roles = [role2]
#      member2.save!
#
#      role2.permissions << permission.name
#      role2.save!
#      role.permissions << permission.name
#      role.save!
#    end
#
#    it { user.allowed_to?(permission.name, [project, project2], {}).should be_true }
#
#  end
#
#  describe "WHEN requesting a permission on two projects
#            WHEN the permission is granted on one project" do
#    before do
#      project2.save!
#
#      create_member_with_roles [role]
#
#      role.permissions << permission.name
#      role.save!
#    end
#
#    it { user.allowed_to?(permission.name, [project, project2], {}).should be_false }
#  end
#
#  describe "WHEN requesting a permission on two projects
#            WHEN the permission is granted on none of the project" do
#
#    it { user.allowed_to?(permission.name, [project, project2], {}).should be_false }
#  end
#
#  describe "WHEN requesting a permission on no project" do
#
#    it { user.allowed_to?(permission.name, [], {}).should be_false }
#  end
#
#  describe "WHEN requesting a global permission
#            WHEN the user is admin" do
#    before do
#      user.admin = true
#    end
#
#    it { user.allowed_to?(permission.name, nil, :global => true).should be_true }
#  end
#
#  describe "WHEN requesting a global permission as anonymous
#            WHEN anonymous is allowed the action" do
#
#    before do
#      anonymous_role.permissions << :action
#      anonymous_role.save!
#    end
#
#    it { User.anonymous.allowed_to?(:action, nil, :global => true, :for => user).should be_true }
#  end
#
#  describe "WHEN requesting a global permission as anonymous
#            WHEN anonymous is not allowed the action" do
#
#    it { User.anonymous.allowed_to?(:action, nil, :global => true, :for => user).should be_false }
#  end
#
#  describe "WHEN requesting a global permission as anonymous
#            WHEN anonymous is not allowed the action
#            WHEN anonymous has a permission for an action that is a granular_for the requested action" do
#
#    before do
#      permission2.instance_variable_set("@granular_for_obj", permission)
#
#      anonymous_role.permissions << :action2
#      anonymous_role.save!
#    end
#
#    it { User.anonymous.allowed_to?(:action, nil, :global => true).should be_true }
#  end
#
#
#  describe "WHEN requesting a global permission
#            WHEN non_members are allowed the action" do
#
#    before do
#      non_member.permissions << :action
#      non_member.save!
#    end
#
#    it { user.allowed_to?(:action, nil, :global => true, :for => user).should be_true }
#  end
#
#  describe "WHEN requesting a global permission
#            WHEN non_members are not allowed the action" do
#
#    it { user.allowed_to?(:action, nil, :global => true, :for => user).should be_false }
#  end
#
#  describe "WHEN requesting a global permission
#            WHEN non_members are not allowed the action
#            WHEN non_member has a permission for an action that is a granular_for the requested action" do
#
#    before do
#      permission2.instance_variable_set("@granular_for_obj", permission)
#
#      non_member.permissions << :action2
#      non_member.save!
#    end
#
#    it { user.allowed_to?(:action, nil, :global => true).should be_true }
#  end
end

