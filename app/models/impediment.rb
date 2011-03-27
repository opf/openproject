class Impediment < Task
  unloadable

  acts_as_list :scope => :project

  before_validation :update_blocks_list, :unless => Proc.new { |i| i.blocks_ids.nil? }

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

  def self.find(*args)
    if args[1] && args[1][:conditions]
      if args[1][:conditions].is_a?(Hash)
        args[1][:conditions][:parent_id] = nil
        args[1][:conditions][:tracker_id] = self.tracker
      elsif args[1][:conditions].is_a?(Array)
        args[1][:conditions][0] += " AND parent_id is NULL AND tracker_id = #{self.tracker}"
      end
    else
      args << {:conditions => {:parent_id => nil, :tracker_id => self.tracker}}
    end

    super
  end

  def self.find_all_updated_since(since, project_id)
    super(since, project_id, true)
  end

  def blocks_ids=(ids)
    @blocks_ids_list = [ids] if ids.is_a?(Integer)
    @blocks_ids_list = ids.split(/\D+/).map{|id| id.to_i} if ids.is_a?(String)
    @blocks_ids_list = ids.map {|id| id.to_i} if ids.is_a?(Array)
  end

  def blocks_ids
    @blocks_ids_list
  end

  def update_with_relationships(params)
    attribs = params.clone.delete_if { |k, v| !safe_attribute_names.include?(k) }

    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?

    attribs[:blocks_ids] = params[:blocks] if params[:blocks] #if blocks param was not sent, that means the impediment was just dragged

    result = journalized_update_attributes(attribs)

    move_after params[:prev] if result

    result
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

  private

  def update_blocks_list
    # Existing relationships not in for_blocking should be removed from the 'blocks' list
    remove_from_blocks_list
    add_to_blocks_list
  end

  def remove_from_blocks_list
    self.relations_from = self.relations_from.reject{|rel| rel.relation_type == IssueRelation::TYPE_BLOCKS && !blocks_ids.include?(rel.issue_to_id) }
  end

  def add_to_blocks_list
    currently_blocking = relations_from.select{|rel| rel.relation_type == IssueRelation::TYPE_BLOCKS}.collect(&:issue_to_id)

    self.blocks_ids.select{ |id| !currently_blocking.include?(id) }.each{ |id|
      rel = relations_from.build(:relation_type => IssueRelation::TYPE_BLOCKS)
      rel.issue_to_id = id
    }
    true
  end

  def validate
    validate_blocks_list
  end

  def validate_blocks_list
    errors.add :blocks, :can_only_contain_tasks_of_current_sprint if relations_from.any?{|rel| rel.relation_type == IssueRelation::TYPE_BLOCKS && rel.issue_to.fixed_version != self.fixed_version }
  end
end