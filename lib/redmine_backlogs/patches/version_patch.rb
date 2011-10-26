require_dependency 'version'

module RedmineBacklogs::Patches::VersionPatch
  def self.included(base)
    base.class_eval do
      unloadable

      has_many :version_settings, :dependent => :destroy
      accepts_nested_attributes_for :version_settings
    end
  end
end

Version.send(:include, RedmineBacklogs::Patches::VersionPatch)
