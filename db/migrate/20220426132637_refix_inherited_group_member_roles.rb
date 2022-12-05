class RefixInheritedGroupMemberRoles < ActiveRecord::Migration[6.1]
  def up
    # When the FixInheritedGroupMemberRoles ran initially, Members
    # where the MemberRoles were inherited from more than one Group where
    # applied incorrectly. Only the MemberRoles of the last Group where kept.
    require Rails.root.join('db/migrate/20200625133727_fix_inherited_group_member_roles.rb')

    # created_on has been renamed to created_at
    Member.reset_column_information
    Principal.reset_column_information

    FixInheritedGroupMemberRoles.new.up
  end
end
