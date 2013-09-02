module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  included do
    #add class-methods (validations, scope) here
  end

  def reschedule_after(date)
    return if date.nil?
    if leaf?
      if start_date.nil? || start_date < date
        self.start_date, self.due_date = date, date + duration - 1
        save
      end
    else
      leaves.each do |leaf|
        # this depends on the "update_parent_attributes" after save hook
        # updating the start/end date of each work package between leaf and self
        leaf.reschedule_after(date)
      end
    end
  end

  # Returns the time scheduled for this work package.
  #
  # Example:
  #   Start Date: 2/26/09, Due Date: 3/04/09,  duration => 7
  #   Start Date: 2/26/09, Due Date: 2/26/09,  duration => 1
  #   Start Date: 2/26/09, Due Date: -      ,  duration => 1
  #   Start Date: -      , Due Date: 2/26/09,  duration => 1
  def duration
    if (start_date && due_date)
      due_date - start_date + 1
    else
      1
    end
  end
end