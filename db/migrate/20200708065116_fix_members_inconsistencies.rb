class FixMembersInconsistencies < ActiveRecord::Migration[6.0]
  def change
    change_column_default :members, :created_on, -> { 'CURRENT_TIMESTAMP' }

    # Update all members without created_on which got created by CTE
    Member.where(created_on: nil).update_all(created_on: Time.now)

    # Delete members without member_roles
    Member.includes(:member_roles).where(member_roles: { id: nil }).destroy_all
  end
end
