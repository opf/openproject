class FixInheritedGroupMemberRoles < ActiveRecord::Migration[6.0]
  def up
    # Delete all member roles that should be inherited by groups
    MemberRole.where.not(inherited_from: nil).delete_all

    # For all group memberships, recreate the member_roles for all users
    # which will auto-create members for the users if necessary
    Member
      .includes(%i[principal])
      .where(users: { type: 'Group' })
      .find_each do |member|
      # Recreate member_roles for all group members
      Groups::UpdateRolesService
        .new(member.principal, current_user: SystemUser.first, contract_class: EmptyContract)
        .call(member: member, send_notifications: false)
    end
  end

  def down
    # Nothing to do
  end
end
