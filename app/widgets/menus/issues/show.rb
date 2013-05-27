module Menus
  module Issues
    module Show

      Redmine::MenuManager.map :'issues/show' do |menu|
        menu.push :edit, { :controller => '/issues',
                           :action => 'edit',
                           :id => @issue }

        menu.push :watch do |locals|
          Helper.new(locals[:controller]).link_for_watching(locals[:issue], locals[:project])
        end

        menu.push :more_functions, {}, :if => Proc.new{ |p| true }, :class => 'drop-down action_menu_more'

        menu.push :log_time, { :controller => '/timelog', :action => 'new', :issue_id => @issue },
                             :class => 'icon icon-time-add',
                             :parent => :more_functions

        menu.push(
          :duplicate,
          { :controller => '/issues', :action => 'new', :project_id => @project, :copy_from => @issue },
          :class => 'icon icon-duplicate',
          :caption => :button_duplicate,
          :parent => :more_functions)

        menu.push(
          :copy,
          { :controller => '/issue_moves', :action => 'new', :id => @issue, :copy_options => {:copy => 't'}}, :class => 'icon icon-copy',
          :caption => :button_copy,
          :parent => :more_functions)

        menu.push(
          :move,
          { :controller => '/issue_moves', :action => 'new', :id => @issue },
          :class => 'icon icon-move',
          :caption => :button_move,
          :parent => :more_functions)

        menu.push :delete, {}, :parent => :more_functions, :caption => :button_delete do |locals|
          Helper.new(locals[:controller]).link_for_deletion(locals[:issue])
        end
      end

      class Helper
        include WatchersHelper
        include Rails.application.routes.url_helpers
        include Redmine::I18n
        include ActionView::Helpers::UrlHelper

        attr_reader :controller

        def initialize(controller)
          @controller = controller
        end

        def link_for_watching(issue, project)
          watcher_link(issue,
                       User.current,
                       { :class => 'watcher_link',
                         :replace => User.current.allowed_to?(:view_issue_watchers, project) ? ['#watchers', '.watcher_link'] : ['.watcher_link'] })
        end

        def link_for_deletion(issue)
          link_to l(:button_delete), { :controller => '/issues',
                                       :action => 'destroy',
                                       :id => issue },
                                     :confirm => (issue.leaf? ? l(:text_are_you_sure) : l(:text_are_you_sure_with_children)),
                                     :remote => true,
                                     :method => :delete ,
                                     :class => 'icon icon-del'
        end
      end
    end
  end
end
