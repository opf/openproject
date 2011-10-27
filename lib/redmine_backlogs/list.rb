module RedmineBacklogs::List
  unloadable

  def self.included(base)
    base.class_eval do
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

    private

    def set_default_prev_positions_silently(prev)
      prev.fixed_version.rebuild_positions(prev.project)
      prev.reload.position
    end
  end
end
