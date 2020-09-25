class MembersAllowNullOnProject < ActiveRecord::Migration[6.0]
  def change
    change_column_null :members, :project_id, true

    # TODO:
    #   * on down, remove all global members
    #   * migrate existing global memberships
    #   * rename created_on to created_at + add updated_at
  end
end
