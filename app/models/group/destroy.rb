module Group::Destroy
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_members
  end

  ##
  # Instead of firing of separate queries for each and every Member and MemberRole
  # instance upon group deletion this implementation does most of the deletion
  # in a hand full of aggregate queries.
  #
  # Instead of doing
  #
  #   Member:
  #     before_destroy :remove_from_category_assignments
  #     after_destroy :unwatch_from_permission_change
  #     after_destroy :destroy_notification
  #
  #   MemberRole:
  #     after_destroy :remove_role_from_group_users
  #
  # for every row all relevant roles are deleted within 5 mass delete queries
  # + 1 query for each member instance for each group itself + number of watchers
  # among the users in the deleted group.
  #
  # Example:
  #
  # Given: 150 projects and 1 group with 20 users which is member in every project
  #
  # That makes 150 * 20 3000 Member rows and also 3000 MemberRole rows.
  #
  # Without this patch this would result in at least 4 queries for each member
  # (the callbacks mentioned above + the deletion of the member) and 2 queries
  # for each MemberRole (callback mentioned above + deletion of the actual MemberRole).
  # Altogether that makes:
  #
  # num_queries_pre_patch = 3000 * 4 + 3000 * 2 + W = 18000 + W
  #
  # Where W is the number of watchers among the users in the destroyed group.
  # The actual number is actually even higher as for the callbacks a bunch of read queries
  # (loading the project, the user, etc.) are triggered, too.
  #
  # With this patch the number of queries is reduced to the 5 + 1 for each group member
  # as explained above, making it:
  #
  # num_queries_post_patch = 5 + 150 + W = 155 + W
  #
  def destroy_members
    MemberRole.transaction do
      members = Member.table_name
      member_roles = MemberRole.table_name

      # Store all project/user combinations for later watcher pruning
      # See: Member#unwatch_from_permission_change
      user_id_and_project_id = Member
                               .joins(
                                 "INNER JOIN #{member_roles} umr
                                    ON #{members}.id = umr.member_id
                                  INNER JOIN #{member_roles} gmr
                                    ON umr.inherited_from = gmr.id
                                  INNER JOIN #{members} gm
                                    ON gm.id = gmr.member_id AND gm.user_id = #{id}"
                               )
                               .distinct
                               .pluck(:user_id, :project_id)

      user_ids, project_ids = user_id_and_project_id.each_with_object([[], []]) do |element, array|
        array.first << element.first
        array.last << element.last
      end

      users = User.find(user_ids)

      # Delete all MemberRoles created through this group for each user within it.
      MemberRole
        .joins("INNER JOIN #{member_roles} b on #{member_roles}.inherited_from = b.id")
        .joins("INNER JOIN #{members} on #{members}.id = b.member_id")
        .where("#{members}.user_id" => id) # group ID
        .delete_all

      # Delete all MemberRoles associating this group itself with a project.
      MemberRole
        .joins("INNER JOIN #{members} on #{members}.id = #{member_roles}.member_id")
        .where("#{members}.user_id" => id)
        .delete_all

      Watcher.prune(user: users, project_id: project_ids)

      # Destroy member instances for this group itself to trigger
      # member destroyed notifications.
      Member
        .where(user_id: id)
        .destroy_all

      # Remove category based auto assignments for this member.
      # See: Member#remove_from_category_assignments
      Category
        .joins("INNER JOIN #{members}
                ON #{members}.project_id = categories.project_id
                AND #{members}.user_id = categories.assigned_to_id")
        .where("#{members}.user_id" => id)
        .update_all "assigned_to_id = NULL"

      self.users.delete_all # remove all users from this group
      reload # so associated member instances are not destroyed again
    end
  end
end
