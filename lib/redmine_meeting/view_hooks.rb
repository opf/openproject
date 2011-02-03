module Plugin
  module Meeting
    class ViewHooks < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        stylesheet_link_tag 'redmine_meeting', :plugin => 'redmine_meeting'
      end
    end
  end
end