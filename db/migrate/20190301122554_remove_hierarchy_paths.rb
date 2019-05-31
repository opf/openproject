require_relative './20180116065518_add_hierarchy_paths'

class RemoveHierarchyPaths < ActiveRecord::Migration[5.2]
  def up
    AddHierarchyPaths.new.migrate :down

    # Set sort to id, asc where parent sort was used
    Query
      .where("sort_criteria LIKE '%parent%'")
      .find_each do |query|
      # Use update_column to ensure that value is saved regardless
      # of the overall state of the query
      query.update_column(:sort_criteria, query.sort_criteria.map { |criteria| map_parent_to_id(criteria) })
    rescue StandardError => e
      warn "Failed to migrate parent sort_criteria for query #{query.id}: #{e}"
    end
  end

  def down
    # Will fail to #rebuild_hierarchy_paths! unless restored to correct version
    AddHierarchyPaths.new.migrate :up

    # Set sort to parent, asc where query.show_hierarchies is set
    # because that is what is implied by the frontend.
    Query
      .where(show_hierarchies: true)
      .update_all(sort_criteria: [%w(parent asc)])
  end

  private

  ##
  # Map parent sort_criteria to id asc.
  def map_parent_to_id(criteria)
    if criteria.first.to_s == 'parent'
      %w[id asc]
    else
      criteria
    end
  end
end
