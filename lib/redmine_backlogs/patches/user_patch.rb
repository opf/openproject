require_dependency 'user'

module RedmineBacklogs::Patches::UserPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods
    end
  end

  module InstanceMethods
    def backlogs_preference(attr, new_value = nil)
      setting = read_backlogs_preference(attr)

      if setting.nil? and new_value.nil?
        new_value = compute_backlogs_preference(attr)
      end

      if new_value.present?
        setting = write_backlogs_preference(attr, new_value)
      end

      setting
    end

    protected

    def read_backlogs_preference(attr)
      setting = self.pref[:"backlogs_#{attr}"]

      setting.blank? ? nil : setting
    end

    def write_backlogs_preference(attr, new_value)
      self.pref[:"backlogs_#{attr}"] = new_value
      self.pref.save! unless self.new_record?

      new_value
    end

    def compute_backlogs_preference(attr)
      case attr
      when :task_color
        ("#%0.6x" % rand(0xFFFFFF)).upcase
      else
        raise "Unsupported attribute '#{attr}'"
      end
    end
  end
end

User.send(:include, RedmineBacklogs::Patches::UserPatch)
