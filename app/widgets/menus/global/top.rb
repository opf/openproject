#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Menus::Global
  module Top
    Redmine::MenuManager.map :'global/top' do |menu|
      menu.push :home, :home_path,
                       :caption => :label_home

      menu.push :my_page, { :controller => '/my',
                            :action => 'page' },
                          :caption => :label_my_page,
                          :if => Proc.new { User.current.logged? }

      menu.push :projects, Project::Content.new,
                           :if => Project::Allowed

      menu.push :administration, { :controller => '/admin',
                                   :action => 'projects' },
                                  :caption => :label_administration,
                                  :if => Proc.new { User.current.admin? }

      menu.push :help, Redmine::Info.help_url,
                       :caption => "?",
                       :html => { :accesskey => Redmine::AccessKeys.key_for(:help) }

      menu.push :my_account, MyAccount::Content.new
    end

    module Project
      class Content
        include Rails.application.routes.url_helpers
        include Redmine::I18n
        include ActionView::Helpers::UrlHelper
        include ActionView::Helpers::FormTagHelper
        include ActionView::Context
        include Redmine::MenuManager::MenuHelper

        attr_reader :controller

        def call(locals)
          @controller = locals[:controller]

          menu = ''.html_safe
          menu << link_to(l(:label_project_plural), { :controller => '/projects',
                                                     :action => 'index' },
                                                   :title => l(:label_project_plural))

          #if User.current.impaired?
            #content_tag :li do
            #  heading
            #end
          #else
            #render_drop_down_menu_node heading do
          unless User.current.impaired?
              menu << content_tag(:ul, :style => "display:none", :class => "menu-children") do
                ret = content_tag :li do
                  link_to l(:label_project_view_all), :controller => '/projects',
                                                      :action => 'index'
                end

                ret += content_tag :li, :id => "project-search-container" do
                  hidden_field_tag("", "", :class => 'select2-select')
                end

                ret
              end
            #end
          end

          menu
        end

      end

      class Allowed
        def self.call(locals)
          !(User.current.anonymous? and Setting.login_required?) &&
          !User.current.number_of_known_projects.zero?
        end
      end
    end

    module MyAccount
      class Content
        include Rails.application.routes.url_helpers
        include Redmine::I18n
        include ActionView::Helpers::UrlHelper
        include ActionView::Context
        include Redmine::MenuManager::MenuHelper

        attr_reader :controller

        def call(locals)
          @controller = locals[:controller]

          items = Redmine::MenuManager.menu_items_for(:account_menu)

          unless User.current.logged?
            render_drop_down_menu_node(link_to(l(:label_login),
                                               { :controller => '/account',
                                                 :action => 'login' },
                                                 :class => 'login',
                                                 :title => l(:label_login)),
                                       :class => "drop-down last-child") do
              content_tag :ul do
                render :partial => 'account/login'
              end
            end
          else
            render_drop_down_menu_node link_to(User.current.name, User.current, :title => User.current.to_s),
                                       items,
                                       :class => "drop-down last-child"
          end

        end
      end
    end
  end
end
