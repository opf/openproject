class Impediment < Task
  unloadable

  def self.create_with_relationships(params, user_id, project_id)
    super(params, user_id, project_id, true)
  end

  def self.find_all_updated_since(since, project_id)
    super(since, project_id, true)
  end

  def update_with_relationships(params)
    super(params, true)
  end

  def update_blocked_list(for_blocking)
    # Existing relationships not in for_blocking should be removed from the 'blocks' list
    relations_from.find(:all, :conditions => "relation_type='blocks'").each{ |ir|
      ir.destroy unless for_blocking.include?( ir[:issue_to_id] )
    }

    already_blocking = relations_from.find(:all, :conditions => "relation_type='blocks'").map{|ir| ir.issue_to_id}

    # Non-existing relationships that are in for_blocking should be added to the 'blocks' list
    for_blocking.select{ |id| !already_blocking.include?(id) }.each{ |id|
      ir = relations_from.new(:relation_type=>'blocks')
      ir[:issue_to_id] = id
      ir.save!
    }
    reload
  end

  def validate_blocks_list(list)
    if list.split(/\D+/).length==0
      errors.add :blocks, :must_have_comma_delimited_list
      false
    else
      true
    end
  end
end