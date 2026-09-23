# frozen_string_literal: true

class MigrateListCustomFieldsToHierarchyItems < ActiveRecord::Migration[8.1]
  def up
    advance_item_sequence
    create_roots
    create_items_and_mappings
    create_closure_rows
    update_children_counts
    update_position_caches
    rewrite_values
    assert_ids_disjoint!

    drop_table :custom_options
  end

  # Best effort. Labels suffixed to resolve duplicates stay suffixed, and items
  # created after the migration come back with fresh option ids.
  def down
    create_table :custom_options do |t|
      t.bigint :custom_field_id
      t.integer :position
      t.boolean :default_value # rubocop:disable Rails/ThreeStateBooleanColumn -- the dropped column was nullable
      t.text :value
      t.timestamps null: true
    end
    add_index :custom_options, :custom_field_id
    add_index :custom_options, :value, using: :gin, opclass: :gin_trgm_ops

    reserve_option_ids
    map_items_added_since_the_migration
    restore_options
    restore_values
    drop_list_hierarchies

    say "Reverted list custom fields to custom options. Duplicate labels keep the suffix applied on the way up."
  end

  private

  def advance_item_sequence
    execute <<~SQL.squish
      SELECT setval('hierarchical_items_id_seq',
                    GREATEST((SELECT last_value FROM hierarchical_items_id_seq),
                             (SELECT last_value FROM custom_options_id_seq)))
    SQL
  end

  def create_roots
    execute <<~SQL.squish
      INSERT INTO hierarchical_items (custom_field_id, children_count, created_at, updated_at)
      SELECT cf.id, 0, NOW(), NOW()
      FROM custom_fields cf
      WHERE cf.field_format = 'list'
        AND NOT EXISTS (SELECT 1 FROM hierarchical_items hi WHERE hi.custom_field_id = cf.id)
    SQL

    execute <<~SQL.squish
      INSERT INTO hierarchical_item_hierarchies (ancestor_id, descendant_id, generations)
      SELECT hi.id, hi.id, 0
      FROM hierarchical_items hi
      JOIN custom_fields cf ON cf.id = hi.custom_field_id AND cf.field_format = 'list'
      WHERE NOT EXISTS (
        SELECT 1 FROM hierarchical_item_hierarchies h
        WHERE h.ancestor_id = hi.id AND h.descendant_id = hi.id
      )
    SQL
  end

  def create_items_and_mappings
    execute <<~SQL.squish
      WITH numbered AS (
        SELECT co.id AS custom_option_id,
               co.custom_field_id,
               co.value,
               COALESCE(co.default_value, false) AS default_value,
               COALESCE(co.created_at, NOW()) AS created_at,
               COALESCE(co.updated_at, NOW()) AS updated_at,
               ROW_NUMBER() OVER (PARTITION BY co.custom_field_id
                                  ORDER BY co.position NULLS LAST, co.id) - 1 AS sort_order,
               ROW_NUMBER() OVER (PARTITION BY co.custom_field_id, co.value
                                  ORDER BY co.position NULLS LAST, co.id) AS dup_rank
        FROM custom_options co
        JOIN custom_fields cf ON cf.id = co.custom_field_id AND cf.field_format = 'list'
      ),
      inserted AS (
        INSERT INTO hierarchical_items
          (parent_id, sort_order, label, default_value, children_count, created_at, updated_at)
        SELECT root.id,
               n.sort_order,
               CASE WHEN n.dup_rank = 1 THEN n.value ELSE n.value || ' (' || n.dup_rank || ')' END,
               n.default_value,
               0,
               n.created_at,
               n.updated_at
        FROM numbered n
        JOIN hierarchical_items root
          ON root.custom_field_id = n.custom_field_id AND root.parent_id IS NULL
        RETURNING id, parent_id, sort_order
      )
      INSERT INTO legacy_custom_option_mappings (custom_option_id, hierarchical_item_id, custom_field_id)
      SELECT n.custom_option_id, ins.id, n.custom_field_id
      FROM inserted ins
      JOIN hierarchical_items root ON root.id = ins.parent_id
      JOIN numbered n ON n.custom_field_id = root.custom_field_id AND n.sort_order = ins.sort_order
    SQL
  end

  def create_closure_rows
    execute <<~SQL.squish
      INSERT INTO hierarchical_item_hierarchies (ancestor_id, descendant_id, generations)
      SELECT i.id, i.id, 0
      FROM hierarchical_items i
      JOIN legacy_custom_option_mappings m ON m.hierarchical_item_id = i.id
      UNION ALL
      SELECT i.parent_id, i.id, 1
      FROM hierarchical_items i
      JOIN legacy_custom_option_mappings m ON m.hierarchical_item_id = i.id
    SQL
  end

  def update_children_counts
    execute <<~SQL.squish
      UPDATE hierarchical_items root
      SET children_count = sub.count
      FROM (
        SELECT parent_id, COUNT(*) AS count
        FROM hierarchical_items
        WHERE parent_id IS NOT NULL
        GROUP BY parent_id
      ) sub
      WHERE root.id = sub.parent_id
        AND root.parent_id IS NULL
        AND EXISTS (SELECT 1 FROM custom_fields cf WHERE cf.id = root.custom_field_id AND cf.field_format = 'list')
    SQL
  end

  def update_position_caches
    root_ids = select_values(<<~SQL.squish)
      SELECT hi.id
      FROM hierarchical_items hi
      JOIN custom_fields cf ON cf.id = hi.custom_field_id AND cf.field_format = 'list'
    SQL

    root_ids.each { |root_id| execute(position_cache_sql(root_id)) }
  end

  # Copied from CustomFields::Hierarchy::HierarchicalItemService so the migration
  # keeps working if that query changes later.
  def position_cache_sql(root_id)
    <<~SQL.squish
      UPDATE hierarchical_items
      SET position_cache = subquery.position
      FROM (
        SELECT hi.id
              , SUM((1 + COALESCE(anc.sort_order, 0)) *
                  POWER(count_max.total_descendants, count_max.max_gens - depths.generations)) AS position
        FROM hierarchical_items hi
             INNER JOIN hierarchical_item_hierarchies hih ON hi.id = hih.descendant_id
             JOIN hierarchical_item_hierarchies anc_h ON anc_h.descendant_id = hih.descendant_id
             JOIN hierarchical_items anc ON anc.id = anc_h.ancestor_id
             JOIN hierarchical_item_hierarchies depths ON depths.ancestor_id = #{root_id} AND depths.descendant_id = anc.id
           , (
            SELECT COUNT(1) AS total_descendants, MAX(generations) + 1 AS max_gens
            FROM hierarchical_items hi
                INNER JOIN hierarchical_item_hierarchies hih ON hi.id = hih.ancestor_id
            WHERE ancestor_id = #{root_id}
            ) count_max
        WHERE hih.ancestor_id = #{root_id}
        GROUP BY hi.id) as subquery
      WHERE hierarchical_items.id = subquery.id;
    SQL
  end

  def rewrite_values
    %w[custom_values customizable_journals].each do |table|
      execute <<~SQL.squish
        UPDATE #{table} t
        SET value = m.hierarchical_item_id::text
        FROM legacy_custom_option_mappings m
        WHERE t.custom_field_id = m.custom_field_id
          AND t.value = m.custom_option_id::text
      SQL
    end
  end

  def assert_ids_disjoint!
    overlapping = select_value(<<~SQL.squish)
      SELECT COUNT(*)
      FROM legacy_custom_option_mappings m
      JOIN hierarchical_items i ON i.id = m.custom_option_id
      JOIN hierarchical_items root ON root.id = i.parent_id
      WHERE root.custom_field_id = m.custom_field_id
    SQL

    return if overlapping.to_i.zero?

    raise ActiveRecord::MigrationError,
          "#{overlapping} legacy custom option ids collide with migrated item ids of the same custom field"
  end

  def reserve_option_ids
    execute <<~SQL.squish
      SELECT setval('custom_options_id_seq',
                    GREATEST((SELECT COALESCE(MAX(custom_option_id), 0) FROM legacy_custom_option_mappings), 1))
    SQL
  end

  def map_items_added_since_the_migration
    execute <<~SQL.squish
      INSERT INTO legacy_custom_option_mappings (custom_option_id, hierarchical_item_id, custom_field_id)
      SELECT nextval('custom_options_id_seq'), i.id, root.custom_field_id
      FROM hierarchical_items i
      JOIN hierarchical_items root ON root.id = i.parent_id
      JOIN custom_fields cf ON cf.id = root.custom_field_id AND cf.field_format = 'list'
      WHERE NOT EXISTS (SELECT 1 FROM legacy_custom_option_mappings m WHERE m.hierarchical_item_id = i.id)
    SQL
  end

  def restore_options
    execute <<~SQL.squish
      INSERT INTO custom_options (id, custom_field_id, "position", default_value, value, created_at, updated_at)
      SELECT m.custom_option_id, m.custom_field_id, i.sort_order + 1, i.default_value, i.label, i.created_at, i.updated_at
      FROM legacy_custom_option_mappings m
      JOIN hierarchical_items i ON i.id = m.hierarchical_item_id
    SQL
  end

  def restore_values
    %w[custom_values customizable_journals].each do |table|
      execute <<~SQL.squish
        UPDATE #{table} t
        SET value = m.custom_option_id::text
        FROM legacy_custom_option_mappings m
        WHERE t.custom_field_id = m.custom_field_id
          AND t.value = m.hierarchical_item_id::text
      SQL
    end
  end

  # Deleting the items cascades the mappings away, so this must come last.
  def drop_list_hierarchies
    execute <<~SQL.squish
      DELETE FROM hierarchical_item_hierarchies h
      USING (#{list_item_ids_sql}) doomed
      WHERE h.ancestor_id = doomed.id OR h.descendant_id = doomed.id
    SQL

    execute <<~SQL.squish
      DELETE FROM hierarchical_items i
      USING (#{list_item_ids_sql}) doomed
      WHERE i.id = doomed.id
    SQL
  end

  def list_item_ids_sql
    <<~SQL.squish
      SELECT i.id
      FROM hierarchical_items i
      JOIN custom_fields cf ON cf.id = i.custom_field_id AND cf.field_format = 'list'
      UNION
      SELECT c.id
      FROM hierarchical_items c
      JOIN hierarchical_items root ON root.id = c.parent_id
      JOIN custom_fields cf ON cf.id = root.custom_field_id AND cf.field_format = 'list'
    SQL
  end
end
