module VersionPatch
  def self.included(base) # :nodoc:

    # Same as typing in the class 
    base.class_eval do
      unloadable

      # Returns the total reported time for this version
      def spent_hours
        @spent_hours ||= TimeEntry.visible.sum(:hours, :include => :issue, :conditions => ["#{Issue.table_name}.fixed_version_id = ?", id]).to_f
      end
    end
  end
end
