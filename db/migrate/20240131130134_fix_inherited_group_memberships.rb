class FixInheritedGroupMemberships < ActiveRecord::Migration[7.0]
  def up
    # Recreate member_roles for all group members
    # due to regression https://community.openproject.org/work_packages/52528
    Group
      .where(id: Member.where(project_id: nil, user_id: Group.select(:id)).select(:user_id))
      .find_each do |group|
      warn "Creating inherited roles for group ##{group.id}"
      Groups::CreateInheritedRolesService
        .new(group, current_user: User.system, contract_class: EmptyContract)
        .call(user_ids: group.user_ids, send_notifications: false, project_ids: nil)
    end
  end

  def down
    # Nothing to do
  end
end
