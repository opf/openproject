# frozen_string_literal: true

class AddLegacyOptionIdToHierarchicalItems < ActiveRecord::Migration[8.1]
  def change
    add_column :hierarchical_items, :legacy_option_id, :bigint,
               comment: "Id of the custom option a list item replaced, still held by bookmarked URLs and API clients. " \
                        "Retired together with the /api/v3/custom_options endpoint."
    add_index :hierarchical_items, :legacy_option_id, unique: true, where: "legacy_option_id IS NOT NULL"
  end
end
