class CreateCustomFieldSections < ActiveRecord::Migration[7.0]
  def up
    create_table :custom_field_sections do |t|
      t.integer :position
      t.string :name
      t.string :type # project or nil (-> work_package)

      t.timestamps
    end

    add_reference :custom_fields, :custom_field_section
    add_column :custom_fields, :position_in_custom_field_section, :integer, null: true

    create_and_assign_default_section
  end

  def down
    remove_reference :custom_fields, :custom_field_section
    remove_column :custom_fields, :position_in_custom_field_section
    drop_table :custom_field_sections
  end

  private

  def create_and_assign_default_section
    # for project custom fields only
    section = ProjectCustomFieldSection.create!(
      name: "Project attributes"
    )

    ActiveRecord::Base.connection.execute <<~SQL.squish
       UPDATE "custom_fields"
       SET
         "position_in_custom_field_section" = "mapping"."new_position",
         "custom_field_section_id" = #{section.id}
       FROM (
         SELECT
           id,
           ROW_NUMBER() OVER (ORDER BY updated_at) AS new_position
         FROM "custom_fields"
         WHERE "custom_fields"."type" = 'ProjectCustomField'
       ) AS "mapping"
       WHERE "custom_fields"."id" = "mapping"."id";
     SQL
  end
end
