class FixInheritedGroupMemberRoles < ActiveRecord::Migration[6.0]
  def up
    # Delete all member roles that should be inherited by groups
    MemberRole.where.not(inherited_from: nil).delete_all

    # For all group memberships, recreate the member_roles for all users
    # which will auto-create members for the users if necessary
    MemberRole
      .joins(member: [:principal])
      .includes(member: %i[principal member_roles])
      .where("#{Principal.table_name}.type" => 'Group')
      .find_each do |member_role|

      # Recreate member_roles for all group members
      member_role.send :add_role_to_group_users
    end
  end

  def down
    # Nothing to do
  end
end
