module Redmine::MenuManager::TopMenuHelper

  def render_top_menu
    content_tag :ul, :id => "account-nav", :class => "menu_root" do
      render_main_top_menu_nodes +
      render_projects_top_menu_node +
      render_module_top_menu_node +
      render_help_top_menu_node +
      render_user_top_menu_node
    end
  end

  private

  def render_projects_top_menu_node(projects = Project.visible)
    return "" if projects.empty? or
      (!User.current.logged? and
       Setting.login_required?)

    heading = link_to l(:label_project_plural), { :controller => 'projects',
                                                  :action => 'index' },
                                                  :title => l(:label_project_plural)

    if User.current.impaired?
      content_tag :li do
        heading
      end
    else
      render_drop_down_menu_node heading do
        content_tag :ul, :style => "display:none" do
          ret = content_tag :li do
            link_to l(:label_project_view_all), :controller => 'projects',
                                                :action => 'index'
          end

          ret += content_tag :li do
            render_project_jump_box projects, :id => "project-search",
                                              :class => "chzn-select",
                                              :'data-placeholder' => "Enter Project Name..."
          end

          ret
        end
      end
    end
  end

  def render_user_top_menu_node(items = menu_items_for(:account_menu))
    unless User.current.logged?
      render_drop_down_menu_node(link_to(l(:label_login),
                                         { :controller => 'account',
                                           :action => 'login' },
                                           :class => 'login',
                                           :title => l(:label_login)),
                                 :class => "drop-down last-child") do
        content_tag :ul do
          render :partial => 'account/login'
        end
      end
    else
      render_drop_down_menu_node link_to_user(User.current, :title => User.current.to_s),
                                 items,
                                 :class => "drop-down last-child"
    end
  end

  def render_module_top_menu_node(items = more_top_menu_items)
    render_drop_down_menu_node link_to(l(:label_modules), "#", :title => l(:label_modules)),
                               items,
                               :id => "more-menu"
  end

  def render_help_top_menu_node(item = help_menu_item)
    render_menu_node(item)
  end

  def render_main_top_menu_nodes(items = main_top_menu_items)
    items.collect do |item|
      render_menu_node(item)
    end.join(" ")
  end
end
