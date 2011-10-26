require_dependency 'version'

module RedmineBacklogs::Patches::VersionPatch
  def self.included(base)
    base.class_eval do
      unloadable

      has_many :version_settings, :dependent => :destroy
      accepts_nested_attributes_for :version_settings

      include InstanceMethods
    end
  end

  module InstanceMethods
    def rebuild_positions(project = self.project)
      return unless project.backlogs_enabled?

#      stories = self.fixed_issues.find(:all, :conditions => {:project_id => project, :tracker_id => Story.trackers, :position => nil}, :order => 'id')
#      stories.sort_by(&:id).each(&:insert_at_top)

      nil
    end
  end
end

Version.send(:include, RedmineBacklogs::Patches::VersionPatch)
