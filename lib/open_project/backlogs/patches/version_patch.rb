require_dependency 'version'

module OpenProject::Backlogs::Patches::VersionPatch
  def self.included(base)
    base.class_eval do
      unloadable

      has_many :version_settings, :dependent => :destroy
      accepts_nested_attributes_for :version_settings

      include Redmine::SafeAttributes
      safe_attributes 'version_settings_attributes'

      include InstanceMethods
    end
  end

  module InstanceMethods
    def rebuild_positions(project = self.project)
      return unless project.backlogs_enabled?

      WorkPackage.transaction do
        # remove position from all non-stories
        WorkPackage.update_all({:position => nil}, ['project_id = ? AND type_id NOT IN (?) AND position IS NOT NULL', project, Story.types])

        # add work_packages w/o position to the top of the list
        # and add work_packages, that have a position, at the end
        stories_wo_position = self.fixed_work_packages.find(:all, :conditions => {:project_id => project, :type_id => Story.types, :position => nil}, :order => 'id')

        stories_w_position = self.fixed_work_packages.find(:all, :conditions => ['project_id = ? AND type_id IN (?) AND position IS NOT NULL', project, Story.types], :order => 'COALESCE(position, 0), id')

        (stories_w_position + stories_wo_position).each_with_index do |story, index|
          story.send(:update_attribute_silently, 'position', index + 1)
        end
      end

      nil
    end

    def ==(other)
      super ||
          other.is_a?(self.class) &&
          id.present? &&
          other.id == id
    end

    def eql?(other)
      self == other
    end

    def hash
      id.hash
    end
  end
end

Version.send(:include, OpenProject::Backlogs::Patches::VersionPatch)
