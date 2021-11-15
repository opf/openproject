class ReplaceInvalidPrincipalReferences < ActiveRecord::Migration[6.1]
  def up
    DeletedUser.reset_column_information
    deleted_user_id = DeletedUser.first.id

    say "Replacing invalid custom value user references"
    CustomValue
      .joins(:custom_field)
      .where("#{CustomField.table_name}.field_format" => 'user')
      .where("value NOT IN (SELECT id::text FROM users)")
      .update_all(value: deleted_user_id)

    say "Replacing invalid responsible user references in work packages"
    WorkPackage
      .where("responsible_id NOT IN (SELECT id FROM users)")
      .update_all(responsible_id: deleted_user_id)
  end

  def down
    # Nothing to do, as only invalid data is fixed
  end
end
