require_dependency 'issue'

module RedmineBacklogs::Patches::IssuePatch
  def self.included(base)
    base.class_eval do
      unloadable

      # The leading and trailing quotes trick the eval code in
      # acts_as_silent_list.  This way, we are able to execute actual code in
      # our quote string. Also sanitize_sql seems to be unavailable in a
      # sensible way. Therefore we're using send to circumvent visibility
      # issues.
      acts_as_silent_list
      def scope_condition
        self.class.send(:sanitize_sql, ['project_id = ? AND fixed_version_id = ? AND tracker_id IN (?)',
                                        self.project_id, self.fixed_version_id, self.trackers])
      end

      # add new items to top of list automatically
      after_create :insert_at, :if => :is_story?

      # reorder list, if issue is removed from sprint
      before_update :fix_other_issues_positions
      before_update :fix_own_issue_position

      # deactivate the default add_to_list_bottom callback
      def add_to_list_bottom
        super unless caller(2).first =~ /callbacks/
      end

      def fix_other_issues_positions
        if changes.slice('project_id', 'tracker_id', 'fixed_version_id').present?
          if changes.slice('project_id', 'fixed_version_id').blank? and
                              Story.trackers.include?(tracker_id.to_i) and
                              Story.trackers.include?(tracker_id_was.to_i)
            return
          end

          if fixed_version_id_changed?
            restore_version_id = true
            new_version_id = fixed_version_id
            self.fixed_version_id = fixed_version_id_was
          end

          if tracker_id_changed?
            restore_tracker_id = true
            new_tracker_id = tracker_id
            self.tracker_id = tracker_id_was
          end

          if project_id_changed?
            restore_project_id = true
            # I've got no idea, why there's a difference between setting the
            # project via project= or via project_id=, but there is.
            new_project = project
            self.project = Project.find(project_id_was)
          end

          remove_from_list if is_story?

          if restore_project_id
            self.project = new_project
          end

          if restore_tracker_id
            self.tracker_id = new_tracker_id
          end

          if restore_version_id
            self.fixed_version_id = new_version_id
          end
        end
      end

      def fix_own_issue_position
        if changes.slice('project_id', 'tracker_id', 'fixed_version_id').present?
          if changes.slice('project_id', 'fixed_version_id').blank? and
                              Story.trackers.include?(tracker_id.to_i) and
                              Story.trackers.include?(tracker_id_was.to_i)
            return
          end

          if is_story? and fixed_version.present?
            insert_at(1)
          else
            assume_not_in_list
          end
        end
      end



      # list end

      include InstanceMethods
      extend ClassMethods

      alias_method_chain :recalculate_attributes_for, :remaining_hours
      before_validation :backlogs_before_validation, :if => lambda {|i| i.project && i.project.module_enabled?("backlogs")}

      before_save :inherit_version_from_story_or_root_task, :if => lambda {|i| i.is_task? }
      after_save  :inherit_version_to_leaf_tasks, :if => lambda {|i| (i.backlogs_enabled? && i.story_or_root_task == i) }

      validates_numericality_of :story_points, :only_integer             => true,
                                               :allow_nil                => true,
                                               :greater_than_or_equal_to => 0,
                                               :less_than                => 10_000,
                                               :if => lambda { |i| i.project && i.project.module_enabled?('backlogs') }

      validates_each :parent_issue_id do |record, attr, value|
        validate_parent_issue_relation(record, attr, value)

        validate_children(record, attr, value) #not using validates_associated because the errors are not displayed nicely then
      end
    end
  end

  module ClassMethods
    def backlogs_trackers
      @backlogs_trackers ||= Story.trackers << Task.tracker
    end

    def take_child_update_semaphore
      @child_updates = true
    end

    def child_update_semaphore_taken?
      @child_updates
    end

    def place_child_update_semaphore
      @child_updates = false
    end

    private
    def validate_parent_issue_relation(issue, parent_attr, value)
      parent = Issue.find_by_id(value)
      if parent_issue_relationship_spanning_projects?(parent, issue)
        issue.errors.add(parent_attr,
                         :parent_child_relationship_across_projects,
                         :issue_name => issue.subject,
                         :parent_name => parent.subject)
      end
    end

    def parent_issue_relationship_spanning_projects?(parent, child)
      child.is_task? && parent.in_backlogs_tracker? && parent.project_id != child.project_id
    end

    def validate_children(issue, attr, value)
      if issue.in_backlogs_tracker?
        issue.children.each do |child|
          unless child.valid?
            child.errors.each do |key, value|
              issue.errors.add(:children, value)
            end
          end
        end
      end
    end
  end

  module InstanceMethods
    def done?
      self.project.issue_statuses.include?(self.status)
    end

    def journalized_update_attributes!(attribs)
      init_journal(User.current)
      update_attributes!(attribs)
    end

    def journalized_update_attributes(attribs)
      init_journal(User.current)
      update_attributes(attribs)
    end

    def journalized_update_attribute(attrib, v)
      init_journal(User.current)
      update_attribute(attrib, v)
    end

    def to_story
      Story.find(id) if is_story?
    end

    def is_story?
      backlogs_enabled? and Story.trackers.include?(self.tracker_id)
    end

    def to_task
      Task.find(id) if is_task?
    end

    def is_task?
      backlogs_enabled? and (self.parent_issue_id && self.tracker_id == Task.tracker && Task.tracker.present?)
    end

    def is_impediment?
      backlogs_enabled? and (self.parent_issue_id.nil? && self.tracker_id == Task.tracker && Task.tracker.present?)
    end

    def trackers
      case
      when is_story?
        Story.trackers
      when is_task?
        Task.trackers
      else
        []
      end
    end

    def story
      if self.is_story?
        return Story.find(self.id)
      elsif self.is_task?
        # Make sure to get the closest ancestor that is a Story, i.e. the one with the highest lft
        # otherwise, the highest parent that is a Story is returned
        story_issue = self.ancestors.find_by_tracker_id(Story.trackers, :order => 'lft DESC')
        return Story.find(story_issue.id) if story_issue
      end
      nil
    end

    def blocks
      # return issues that I block that aren't closed
      return [] if closed?
      relations_from.collect {|ir| ir.relation_type == 'blocks' && !ir.issue_to.closed? ? ir.issue_to : nil}.compact
    end

    def blockers
      # return issues that block me
      return [] if closed?
      relations_to.collect {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed? ? ir.issue_from : nil}.compact
    end

    def recalculate_attributes_for_with_remaining_hours(issue_id)
      recalculate_attributes_for_without_remaining_hours(issue_id)

      if issue_id && p = Issue.find_by_id(issue_id)
        if p.left != (p.right + 1) # this node has children
          p.update_attribute(:remaining_hours, p.leaves.sum(:remaining_hours).to_f)
        end
      end
    end

    def inherit_version_from(source)
      self.fixed_version_id = source.fixed_version_id if source
    end

    def backlogs_enabled?
      self.project.try(:module_enabled?, "backlogs")
    end

    def in_backlogs_tracker?
      backlogs_enabled? and Issue.backlogs_trackers.include?(self.tracker.id)
    end

    def story_or_root_task
      return nil unless in_backlogs_tracker?
      return self if self.is_story?

      root = self
      unless self.parent_issue_id.nil?

        real_parent = Issue.find_by_id(self.parent_issue_id)
        #unfortunately the nested set is only build on save
        #hence, the #parent method is not always correct
        #therefore we go to the parent the hard way and use nested set from there
        ancestors = real_parent.ancestors.find_all_by_tracker_id(Issue.backlogs_trackers)
        ancestors ? ancestors << real_parent : [real_parent]

        root = ancestors.sort_by(&:right).find { |i| i.is_story? or i.is_impediment? }
      end

      root
    end

    private

    def backlogs_before_validation
      if self.tracker_id == Task.tracker
        self.estimated_hours = self.remaining_hours if self.estimated_hours.blank? && ! self.remaining_hours.blank?
        self.remaining_hours = self.estimated_hours if self.remaining_hours.blank? && ! self.estimated_hours.blank?
      end
    end

    def inherit_version_from_story_or_root_task
      root = story_or_root_task
      inherit_version_from(root) if root != self
    end

    def inherit_version_to_leaf_tasks
      unless Issue.child_update_semaphore_taken?
        begin
          Issue.take_child_update_semaphore

          # we overwrite the version of all leaf issues that are tasks. This way,
          # the fixed_version_id is propagated up by the
          # inherit_version_from_story_or_root_task before_filter and the
          # update_parent_attributes after_filter
          stop_descendants, descendant_tasks = self.descendants.partition{|d| d.tracker_id != Task.tracker }
          descendant_tasks.reject!{ |t| stop_descendants.any? { |s| s.left < t.left && s.right > t.right } }
          leaf_tasks = descendant_tasks.reject{ |t| descendant_tasks.any? { |s| s.left > t.left && s.right < t.right } }

          leaf_tasks.each do |task|
            task.inherit_version_from(self)
            task.save! if task.changed?
          end
        ensure
          Issue.place_child_update_semaphore
        end
      end
    end
  end
end

Issue.send(:include, RedmineBacklogs::Patches::IssuePatch)
