class AddUniquenessConstrainOnLastnameForGroupsAndPlaceholderUsers < ActiveRecord::Migration[6.1]
  def up
    # Partial unique index
    execute <<-SQL
      CREATE UNIQUE INDEX unique_lastname_for_groups_and_placeholder_users ON
        users (lastname, type)
        WHERE (type = 'Group' OR type = 'PlaceholderUser');
    SQL
  end

  def down
    # Remove unique index
    execute <<-SQL
          DROP INDEX IF EXISTS unique_lastname_for_groups_and_placeholder_users;
    SQL
  end
end
