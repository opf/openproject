module WYSIWYGEditing::Hooks
  class LayoutHook < Redmine::Hook::ViewListener
    include RbCommonHelper

    def view_my_account(context={ })
      return context[:controller].send(:render_to_string, {
          :partial => 'shared/view_my_account_wysiwyg',
          :locals => {:user => context[:user], :enabled => context[:user].wysiwyg_editing_preference(:enabled) }
        })
    end
  end
end
