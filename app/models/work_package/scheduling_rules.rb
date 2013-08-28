module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  included do

  end

  # Returns the time scheduled for this issue.
  #
  # Example:
  #   Start Date: 2/26/09, End Date: 3/04/09
  #   duration => 6
  def duration
    (start_date && due_date) ? due_date - start_date : 0
  end

  def reschedule_after(date)
    return if date.nil?
    if leaf?
      if start_date.nil? || start_date < date
        self.start_date, self.due_date = date, date + duration
        save
      end
    else
      leaves.each do |leaf|
        leaf.reschedule_after(date)
      end
    end
  end
end