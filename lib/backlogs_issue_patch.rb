require_dependency 'issue'

module Backlogs
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :move_to_project_without_transaction, :autolink
        alias_method_chain :recalculate_attributes_for, :remaining_hours
        before_validation :backlogs_before_validation
        after_save  :backlogs_after_save
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def move_to_project_without_transaction_with_autolink(new_project, new_tracker = nil, options = {})
        newissue = move_to_project_without_transaction_without_autolink(new_project, new_tracker, options)

        if !!newissue and self.project_id == newissue.project_id and self.is_story? and newissue.is_story? and self.id != newissue.id
          relation = IssueRelation.new :relation_type => IssueRelation::TYPE_DUPLICATES
          relation.issue_from = self
          relation.issue_to = newissue
          relation.save
        end

        return newissue
      end

      def journalized_update_attributes!(attribs)
        self.init_journal(User.current)
        return self.update_attributes!(attribs)
      end

      def journalized_update_attributes(attribs)
        self.init_journal(User.current)
        return self.update_attributes(attribs)
      end

      def journalized_update_attribute(attrib, v)
        self.init_journal(User.current)
        self.update_attribute(attrib, v)
      end

      def is_story?
        return Story.trackers.include?(self.tracker_id)
      end

      def is_task?
        return (self.parent_id && self.tracker_id == Task.tracker)
      end

      def story
        if self.is_story?
          return self
        else
          return self.ancestors.find_by_tracker_id(Story.trackers)
        end
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
        return nil if !self.is_story? || ! self.story_points || self.story_points <= 0

        dpp = self.project.scrum_statistics.info[:average_days_per_point]
        return nil if ! dpp

        return Integer(self.story_points * dpp)
      end

      def recalculate_attributes_for_with_remaining_hours(issue_id)
        recalculate_attributes_for_without_remaining_hours(issue_id)

        if issue_id && p = Issue.find_by_id(issue_id)
          if p.left != (p.right + 1) # this node has children
            p.update_attribute(:remaining_hours, p.leaves.sum(:remaining_hours).to_f)
          end
        end
      end

      def backlogs_before_validation
        if self.tracker_id == Task.tracker
          self.estimated_hours = self.remaining_hours if self.estimated_hours.blank? && ! self.remaining_hours.blank?
          self.remaining_hours = self.estimated_hours if self.remaining_hours.blank? && ! self.estimated_hours.blank?
        end
      end

      def backlogs_after_save
        ## automatically sets the tracker to the task tracker for
        ## any descendant of story, and follow the version_id
        ## Normally one of the _before_save hooks ought to take
        ## care of this, but appearantly neither root_id nor
        ## parent_id are set at that point

        touched_sprints = []

        if self.is_story?
          # raw sql here because it's efficient and not
          # doing so causes an update loop when Issue calls
          # update_parent

          if not Task.tracker.nil?
            tasks = self.descendants.collect{|t| connection.quote(t.id)}.join(",")
            if tasks != ""
              connection.execute("update issues set tracker_id=#{connection.quote(Task.tracker)}, fixed_version_id=#{connection.quote(self.fixed_version_id)} where id in (#{tasks})")
            end
          end

          touched_sprints = [self.fixed_version_id, self.fixed_version_id_was].compact.uniq
          touched_sprints = touched_sprints.collect{|s| Sprint.find(s)}.compact

        elsif not Task.tracker.nil?
          begin
            story = self.story
            if not story.blank?
              connection.execute "update issues set tracker_id = #{connection.quote(Task.tracker)}, fixed_version_id = #{connection.quote(story.fixed_version_id)} where id = #{connection.quote(self.id)}"
            end

            touched_sprints = [self.root_id, self.root_id_was].compact.uniq.collect{|s| Story.find(s).fixed_version}.compact
          end
        end

        touched_sprints.each {|sprint|
          sprint.touch_burndown
        }
      end

    end
  end
end

Issue.send(:include, Backlogs::IssuePatch) unless Issue.included_modules.include? Backlogs::IssuePatch
