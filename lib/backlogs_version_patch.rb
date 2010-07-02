require_dependency 'version'

module Backlogs
  module VersionPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end
  
    module ClassMethods
    end
  
    module InstanceMethods
      def touch_burndown
        today = connection.quote(Date.today)
        tomorrow = connection.quote(Date.today + 1)
        # not the same as between
        connection.execute "delete from burndown_days where created_at >= #{today} and created_at < #{tomorrow}"
      end
  
      def burndown
        return Sprint.find_by_id(self.id).burndown
      end
  
    end
  end
end

Version.send(:include, Backlogs::VersionPatch) unless Version.included_modules.include? Backlogs::VersionPatch
