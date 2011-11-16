module Backlogs::List
  unloadable

  def self.included(base)
    base.class_eval do
      unloadable

      acts_as_silent_list

      # add new items to top of list automatically
      after_create :insert_at, :if => :is_story?

      # deactivate the default add_to_list_bottom callback
      def add_to_list_bottom
        super unless caller(2).first =~ /callbacks/
      end


      # reorder list, if issue is removed from sprint
      before_update :fix_other_issues_positions
      before_update :fix_own_issue_position


      # Used by acts_as_silent_list to limit the list to a certain subset within
      # the table.
      # Also sanitize_sql seems to be unavailable in a sensible way. Therefore
      # we're using send to circumvent visibility issues.
      def scope_condition
        self.class.send(:sanitize_sql, ['project_id = ? AND fixed_version_id = ? AND tracker_id IN (?)',
                                        self.project_id, self.fixed_version_id, self.trackers])
      end

      include InstanceMethods
    end
  end

  module InstanceMethods


    def move_after(prev_id)
      # remove so the potential 'prev' has a correct position
      remove_from_list
      reload

      prev = self.class.find_by_id(prev_id.to_i)

      # if it should be the first story, move it to the 1st position
      if prev.blank?
        insert_at
        move_to_top

      # if its predecessor has no position, create an order on position silently.
      # This can happen when sorting inside a version for the first time after backlogs was activated
      # and there have already been items inside the version at the time of backlogs activation
      elsif !prev.in_list?
        prev_pos = set_default_prev_positions_silently(prev)
        insert_at(prev_pos += 1)

      # there's a valid predecessor
      else
        insert_at(prev.position + 1)
      end
    end

    protected

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

    def set_default_prev_positions_silently(prev)
      prev.fixed_version.rebuild_positions(prev.project)
      prev.reload.position
    end
  end
end
