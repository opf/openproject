# frozen_string_literal: true

class ModifyFriendlyIdSlugsConstraints < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate NULL scope rows, keeping the most recent one per (slug, sluggable_type)
    say_with_time "Cleaning up duplicate NULL scope rows" do
      execute <<~SQL.squish
        DELETE FROM friendly_id_slugs
        WHERE scope IS NULL
          AND id NOT IN (
            SELECT DISTINCT ON (slug, sluggable_type) id
            FROM friendly_id_slugs
            WHERE scope IS NULL
            ORDER BY slug, sluggable_type, created_at DESC NULLS LAST, id DESC
          );
      SQL
    end

    say_with_time "Cleaning up NULL sluggable_type rows" do
      execute <<~SQL.squish
        DELETE FROM friendly_id_slugs
        WHERE sluggable_type IS NULL;
      SQL
    end

    change_column_null :friendly_id_slugs, :sluggable_type, false

    remove_index :friendly_id_slugs,
                 name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"

    # create index that treats every null value as unique
    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope
      ON friendly_id_slugs (slug, sluggable_type, scope)
      NULLS NOT DISTINCT;
    SQL
  end

  def down
    remove_index :friendly_id_slugs,
                 name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"

    change_column_null :friendly_id_slugs, :sluggable_type, true

    add_index :friendly_id_slugs,
              %i[slug sluggable_type scope],
              unique: true,
              name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope"
  end
end
