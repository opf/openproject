class Impediment < Task
  unloadable

  acts_as_list :scope => :project

  attr_accessor :blocks_ids_list

  before_validation :update_blocked_list, :unless => Proc.new { |i| i.blocks_ids_list.nil? }

  def self.create_with_relationships(params, user_id, project_id)
    task = new

    task.author_id  = user_id
    task.project_id = project_id
    task.tracker_id = Task.tracker

    task.safe_attributes = params
    task.remaining_hours = 0 if IssueStatus.find(params[:status_id]).is_closed?

    task.blocks_ids = params[:blocks]

    if task.save
      task.move_after params[:prev]
    end

    return task
  end

  def self.find_all_updated_since(since, project_id)
    super(since, project_id, true)
  end

  def blocks_ids=(ids)
    blocks_ids_list = [ids] if ids.is_a?(Integer)
    blocks_ids_list = ids.split(/\D+/).map{|id| id.to_i} if ids.is_a?(String)
    blocks_ids_list = ids.map {|id| id.to_i} if ids.is_a?(Array)
  end

  def blocks_ids
    blocks_ids_list
  end

  def update_with_relationships(params)
    attribs = params.clone.delete_if { |k, v| !safe_attribute_names.include?(k) }

    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?

    blocks_ids = params[:blocks] if params[:blocks] #if blocks param was not sent, that means the impediment was just dragged

    if valid? && result = journalized_update_attributes!(attribs)
      move_after params[:prev]
      result
    else
      false
    end
    #blocks_ids =
    #valid_relationships = params[:blocks] ? validate_blocks_list(params[:blocks]) : true #if blocks param was not sent, that means the impediment was just dragged

#    if valid_relationships && result = journalized_update_attributes!(attribs)
#      move_after params[:prev]
#      update_blocked_list params[:blocks].split(/\D+/) if params[:blocks]
#      result
#    else
#      false
#    end
  end

  def move_after(prev_id)
    # remove so the potential 'prev' has a correct position
    remove_from_list

    begin
      prev = self.class.find(prev_id)
    rescue ActiveRecord::RecordNotFound
      prev = nil
    end

    # if it's the first story, move it to the 1st position
    if prev.blank?
      insert_at
      move_to_top

    # if its predecessor has no position (shouldn't happen), make it
    # the last story
    elsif !prev.in_list?
      insert_at
      move_to_bottom

    # there's a valid predecessor
    else
      insert_at(prev.position + 1)
    end
  end

  def update_blocked_list
    for_blocking = blocks_ids_list
    # Existing relationships not in for_blocking should be removed from the 'blocks' list
    remove_from_blocks_list
    # Non-existing relationships that are in for_blocking should be added to the 'blocks' list
    add_to_blocks_list

    reload
  end

  def remove_from_blocks_list
    relations_from.find(:all, :conditions => "relation_type='blocks'").each{ |ir|
      relations_from.reject{|rel| !blocks_ids.include?(rel.issue_to_id) }  # ir.destroy unless blocks_ids.include?( ir[:issue_to_id] )
    }
  end

  def add_to_blocks_list
    currently_blocking = relations_from.find(:all, :conditions => "relation_type='blocks'").map{|ir| ir.issue_to_id}

    blocks_ids.select{ |id| !currently_blocking.include?(id) }.each{ |id|
      relations_from.build(:relation_type=>'blocks', :issue_to_id => id)
    }
  end

  def validate_blocks_list(block_list)
    ids = block_list.split(/\D+/)
    errors.add :blocks, :must_have_comma_delimited_list if ids.length==0
    errors.add :blocks, :can_only_contain_tasks_of_current_sprint  if Task.find(ids).any?{|t| t.impediment? || t.fixed_version != self.fixed_version }
  end
end