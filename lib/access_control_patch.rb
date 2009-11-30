module AccessControlPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    
    # Same as typing in the class
    base.class_eval do
      unless singleton_methods.include? "allowed_actions_without_inheritance"
        class << self
          alias_method_chain :allowed_actions, :inheritance
        end
      end
    end

  end

  module ClassMethods
    def allowed_actions_with_inheritance(permission_name)
      my_actions = allowed_actions_without_inheritance(permission_name)
      my_actions | permission(permission_name).inherits.collect(&:actions)
    end
  end
end