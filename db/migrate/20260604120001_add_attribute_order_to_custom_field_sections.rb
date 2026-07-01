# frozen_string_literal: true

class AddAttributeOrderToCustomFieldSections < ActiveRecord::Migration[8.0]
  def up
    add_column :custom_field_sections, :attribute_order, :string, array: true, null: false, default: []
    # Populate attribute_order for every section from the existing position ordering.
    # COALESCE handles sections that currently have no custom fields (ARRAY_AGG returns NULL).
    execute(<<~SQL.squish)
      UPDATE custom_field_sections cs
      SET attribute_order = COALESCE(
        (
          SELECT ARRAY_AGG('cf_' || cf.id::text ORDER BY cf.position_in_custom_field_section)
          FROM custom_fields cf
          WHERE cf.custom_field_section_id = cs.id
        ),
        '{}'
      )
      WHERE cs.type = 'UserCustomFieldSection'
    SQL

    # Prepend the five built-in user attributes to the first UserCustomFieldSection
    # (the one with the lowest position).  This is idempotent if run more than once.
    execute(<<~SQL.squish)
      UPDATE custom_field_sections
      SET attribute_order =
        ARRAY['login', 'firstname', 'lastname', 'mail', 'language'] || attribute_order
      WHERE id = (
        SELECT id FROM custom_field_sections
        WHERE type = 'UserCustomFieldSection'
        ORDER BY position
        LIMIT 1
      )
    SQL
  end

  def down
    # Restore per-section positions from attribute_order in case they have been
    # changed already.
    # UNNEST … WITH ORDINALITY yields each key with its 1-based rank.
    # Built-in keys (login, firstname, …) don't follow the cf_<id> pattern
    # and are filtered out by the regex so the cast to integer is safe.
    execute(<<~SQL.squish)
      UPDATE custom_fields cf
      SET position_in_custom_field_section = positions.ordinal
      FROM (
        SELECT
          SUBSTRING(key FROM 4)::integer AS cf_id,
          ordinal::integer
        FROM custom_field_sections cs,
          LATERAL UNNEST(cs.attribute_order) WITH ORDINALITY AS unnested(key, ordinal)
        WHERE cs.type = 'UserCustomFieldSection'
          AND key ~ '^cf_[0-9]+$'
      ) positions
      WHERE cf.id = positions.cf_id
    SQL

    remove_column :custom_field_sections, :attribute_order
  end
end
