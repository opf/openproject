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

      stories_wo_position = self.fixed_issues.find(:all, :conditions => {:project_id => project, :tracker_id => Story.trackers, :position => nil}, :order => 'id')

      if stories_wo_position.present?
        stories_w_position = self.fixed_issues.find(:all, :conditions => ['project_id = ? AND tracker_id = ? AND position IS NOT NULL', project, Story.trackers], :order => 'position')

        Issue.transaction do
          # add issues w/o position to the top of the list
          # and add issues, that have a position, at the end

          stories_wo_position.each_with_index do |story, index|
            story.send(:update_attribute_silently, 'position', index + 1)
          end

          stories_w_position.each_with_index do |story, index|
            story.send(:update_attribute_silently, 'position', index + 1 + stories_wo_position.size)
          end
        end
      end

      nil
    end
  end
end

Version.send(:include, RedmineBacklogs::Patches::VersionPatch)
