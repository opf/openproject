module Menus
  module Issues
    module Show

      Redmine::MenuManager.map :'issues/show' do |menu|
        menu.push :edit, { :controller => '/issues',
                           :action => 'edit',
                           :id => :issue },
                         :html => { :class => 'edit icon icon-edit' }

        menu.push :watch, Watch.new

        menu.push :more_functions, Proc.new {|x| '<a class="icon icon-more" href="javascript:">Weitere Funktionen</a>' },
                                   :caption => :more_actions,
                                   :if => Proc.new{ |p| true },
                                   :html => { :class => 'drop-down action_menu_more icon icon-more' }

        menu.push :log_time, { :controller => '/timelog',
                               :action => 'new',
                               :id => :issue },
                             :html => { :class => 'icon icon-time-add' },
                             :caption => :button_log_time,
                             :parent => :more_functions

        menu.push(
          :duplicate,
          { :controller => '/issues',
            :action => 'new',
            :project_id => :project,
            :copy_from => :issue },
          :html => { :class => 'icon icon-duplicate' },
          :caption => :button_duplicate,
          :parent => :more_functions)

        menu.push(
          :copy,
          { :controller => '/issue_moves',
            :action => 'new',
            :id => :issue,
            :copy_options => {:copy => 't'}},
          :html => { :class => 'icon icon-copy' },
          :caption => :button_copy,
          :parent => :more_functions
        )

        menu.push(
          :move,
          { :controller => '/issue_moves',
            :action => 'new',
            :id => :issue },
          :html => { :class => 'icon icon-move' },
          :caption => :button_move,
          :parent => :more_functions
        )

        menu.push :delete, Delete.new,
                           { :parent => :more_functions,
                             :caption => :button_delete }

      end

      class LinkCreator
        include WatchersHelper
        include Rails.application.routes.url_helpers
        include Redmine::I18n
        include ActionView::Helpers::UrlHelper

        attr_reader :controller

        def call(locals)
          # this is required for generating urls
          # as the included modules assume to be included into something responding to controller

          controller = locals[:controller]
        end
      end

      class Watch < LinkCreator
        def call(locals)
          super

          link_for_watching(locals[:issue], locals[:project])
        end

        private

        def link_for_watching(issue, project)
          watcher_link(issue,
                       User.current,
                       { :class => 'watcher_link',
                         :replace => User.current.allowed_to?(:view_issue_watchers, project) ? ['#watchers', '.watcher_link'] : ['.watcher_link'] })
        end
      end

      class Delete < LinkCreator

        def call(locals)
          super

          link_for_deletion(locals[:issue])
        end

        private

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
