require_dependency 'user'

module WYSIWYGEditing::Patches::UserPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods
    end
  end

  module InstanceMethods
    def wysiwyg_editing_preference(attr, new_value = nil)
      setting = read_wysiwyg_editing_preference(attr)

      if setting.nil? and new_value.nil?
        new_value = compute_wysiwyg_editing_preference(attr)
      end

      if !new_value.nil?
        setting = write_wysiwyg_editing_preference(attr, new_value)
      end

      setting
    end

    protected

    def read_wysiwyg_editing_preference(attr)
      self.pref[:"wysiwyg_editing_#{attr}"]
    end

    def write_wysiwyg_editing_preference(attr, new_value)
      self.pref[:"wysiwyg_editing_#{attr}"] = new_value
      self.pref.save! unless self.new_record?

      new_value
    end

    def compute_wysiwyg_editing_preference(attr)
      case attr
      when :enabled
        false
      else
        raise "Unsupported attribute '#{attr}'"
      end
    end
  end
end

User.send(:include, WYSIWYGEditing::Patches::UserPatch)
