class UniqueMemberRole < ActiveRecord::Migration[6.0]
  def change
    change_table :member_roles do |t|
      t.index %i[member_id role_id inherited_from],
              name: 'unique_inherited_role',
              unique: true
    end
  end
end
