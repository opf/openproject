require_dependency 'my_controller'

module OpenProject::Backlogs::Patches::MyControllerPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods

      after_filter :save_backlogs_preferences, :only => [:account]
    end
  end

  module InstanceMethods
    def save_backlogs_preferences
      if request.put? && flash[:notice] == l(:notice_account_updated)
        User.current.backlogs_preference(:versions_default_fold_state, params[:backlogs][:versions_default_fold_state] || "open")
        color = (params[:backlogs] ? params[:backlogs][:task_color] : '').to_s
        if color == '' || color.match(/^#[A-Fa-f0-9]{6}$/)
          User.current.backlogs_preference(:task_color, color)
        else
          flash[:notice] = "Invalid task color code #{color}"
        end
      end
    end
  end
end

MyController.send(:include, OpenProject::Backlogs::Patches::MyControllerPatch)
