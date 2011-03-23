require_dependency 'version'

module Backlogs
  module VersionPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :version_setting
        accepts_nested_attributes_for :version_setting

        named_scope :displayed_left, lambda { |project| { :include => :version_setting,
                                                          :conditions => ["version_settings.display = ? AND versions.project_id = ?",
                                                                          VersionSetting::DISPLAY_LEFT, project.id] } }

        named_scope :displayed_right, lambda { |project| { :include => :version_setting,
                                                          :conditions => ["version_settings.display = ? AND versions.project_id = ?",
                                                                          VersionSetting::DISPLAY_RIGHT, project.id] } }
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def touch_burndown
        BurndownDay.find(:all,
          :joins => :version,
          :conditions => ['burndown_days.version_id = ? and (burndown_days.created_at >= ? or burndown_days.created_at >= versions.effective_date)', self.id, Date.today]
        ).each {|bdd|
          BurndownDay.destroy(bdd.id)
        }
      end

      def burndown
        return Sprint.find_by_id(self.id).burndown
      end

    end
  end
end

Version.send(:include, Backlogs::VersionPatch) unless Version.included_modules.include? Backlogs::VersionPatch
