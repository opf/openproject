require_dependency 'version'

module CostsVersionPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :spent_hours, :inheritance
    end
  end
  
  module InstanceMethods
    def spent_hours_with_inheritance
      # overwritten method
      @spent_hours ||= TimeEntry.visible.sum(:hours, :include => :issue, :conditions => ["#{Issue.table_name}.fixed_version_id = ?", id]).to_f
    end
  end
end

Version.send(:include, CostsVersionPatch)