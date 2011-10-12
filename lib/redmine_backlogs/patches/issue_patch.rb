module RedmineBacklogs::Patches::IssuePatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods
      extend ClassMethods

      unloadable

      alias_method_chain :recalculate_attributes_for, :remaining_hours
      before_validation :backlogs_before_validation, :if => lambda {|i| i.project && i.project.module_enabled?("backlogs")}

      after_save  :touch_sprint_burndowns
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
      @backlogs_tracker ||= Story.trackers << Task.tracker
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
      child.is_task? && backlogs_trackers.include?(parent.tracker_id) &&
                      parent.present? && parent.project_id != child.project_id
    end

    def validate_children(issue, attr, value)
      if issue.backlogs_enabled? && Issue.backlogs_trackers.include?(issue.tracker_id)
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

    def is_story?
      backlogs_enabled? and Story.trackers.include?(self.tracker_id)
    end

    def is_task?
      backlogs_enabled? and (self.parent_issue_id && self.tracker_id == Task.tracker && Task.tracker.present?)
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

    def velocity_based_estimate
      return nil if !self.is_story? || !self.story_points || self.story_points <= 0

      dpp = self.project.scrum_statistics.info[:average_days_per_point]
      return nil if !dpp

      (self.story_points * dpp).to_i
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

    def story_or_root_task
      return nil unless Issue.backlogs_trackers.include?(self.tracker_id)
      return self if self.is_story?

      root = self
      unless self.parent_issue_id.nil?

        real_parent = Issue.find_by_id(self.parent_issue_id)
        #unfortunately the nested set is only build on save
        #hence, the #parent method is not always correct
        #therefore we go to the parent the hard way and use nested set from there
        ancestors = real_parent.ancestors.find_all_by_tracker_id(Issue.backlogs_trackers)
        ancestors ? ancestors << real_parent : [real_parent]

        ancestors.sort_by{ |a| a.right }.each do |p|
          root = p if Issue.backlogs_trackers.include?(p.tracker_id)
          break if Story.trackers.include?(p.tracker_id)
        end
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

          # we overwrite the version of all leaf issues that are tasks
          # this way, the fixed_version_id is propagated up
          # by the inherit_version_from_story_or_root_task before_filter and the update_parent_attributes after_filter
          stop_descendants, descendant_tasks = self.descendants.partition{|d| d.tracker_id != Task.tracker }
          descendant_tasks.reject!{ |t| stop_descendants.any?{ |s| s.left < t.left && s.right > t.right } }
          leaf_tasks = descendant_tasks.reject{ |t| descendant_tasks.any?{ |s| s.left > t.left && s.right < t.right } }

          leaf_tasks.each do |task|
            task.inherit_version_from(self)
            task.save! if task.changed?
          end
        ensure
          Issue.place_child_update_semaphore
        end
      end
    end

    def touch_sprint_burndowns
      ## Normally one of the _before_save hooks ought to take
      ## care of this, but appearantly neither root_id nor
      ## parent_id are set at that point

      touched_sprints = []
      story = self.story

      if self.is_story?
        touched_sprints = Sprint.find_all_by_id(
          [self.fixed_version_id, self.fixed_version_id_was].compact)
      elsif self.is_task?
        # for tasks we touch the sprints of the current and former stories
        story_was = nil
        story_was = Issue.find(self.parent_id_was).story if self.parent_id_was
        touched_sprints = [story, story_was].compact.collect{ |s| s.fixed_version }
      end

      touched_sprints.compact.uniq.each do |sprint|
        sprint.touch_burndown
      end
    end
  end
end

Issue.send(:include, RedmineBacklogs::Patches::IssuePatch)
