require_dependency 'my_controller'

module WYSIWYGEditing::Patches::MyControllerPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods

      after_filter :save_wysiwyg_editing_preferences, :only => [:account]
    end
  end

  module InstanceMethods
    def save_wysiwyg_editing_preferences
      if request.post? && flash[:notice] == l(:notice_account_updated)
        enabled = (params[:wysiwyg_editing] ? params[:wysiwyg_editing][:enabled] : '0').to_s
        User.current.wysiwyg_editing_preference :enabled, enabled == '1'
      end
    end
  end
end

MyController.send(:include, WYSIWYGEditing::Patches::MyControllerPatch)
