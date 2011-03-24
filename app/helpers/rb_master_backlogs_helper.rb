module RbMasterBacklogsHelper
  unloadable

  include Redmine::I18n

  def render_backlog_menu(backlog)
    content_tag(:div, :class => 'menu') do
      [
        content_tag(:div, '', :class => "icon ui-icon ui-icon-carat-1-s"),
        content_tag(:ul, :class => 'items') do

          backlog_menu_items_for(backlog).map do |item|
            content_tag(:li, item, :class => 'item')
          end

        end
      ]
    end
  end

  def backlog_menu_items_for(backlog)
    items = common_backlog_menu_items_for(backlog)

    if backlog.sprint_backlog?
      items += sprint_backlog_menu_items_for(backlog)
    else
      items += owner_backlog_menu_items_for(backlog)
    end

    items
  end

  def common_backlog_menu_items_for(backlog)
    items = []

    items << content_tag(:a, l('backlogs.add_new_story'), :href => '#', :class => 'add_new_story')

    items << link_to(l(:label_stories_tasks),
                     :controller => 'rb_queries',
                     :action => 'show',
                     :project_id => @project,
                     :sprint_id => backlog.sprint)
  end

  def sprint_backlog_menu_items_for(backlog)
    items = []

    items << link_to(l(:label_task_board),
                     :controller => 'rb_taskboards',
                     :action => 'show',
                     :sprint_id => backlog.sprint)

    if backlog.sprint_backlog? and backlog.sprint.has_burndown
      items << content_tag(:a, l('backlogs.show_burndown_chart'), :href => '#', :class => 'show_burndown_chart')
    end

    if Cards::TaskboardCards.selected_label.present?
      items << link_to(l(:label_sprint_cards),
                       :controller => 'rb_stories',
                       :action => 'index',
                       :project_id => @project,
                       :sprint_id => backlog.sprint,
                       :format => :pdf)
    end

    if @project.module_enabled? "wiki"
      items << link_to(l(:label_wiki),
                       :controller => 'rb_wikis',
                       :action => 'edit',
                       :project_id => @project.id,
                       :sprint_id => backlog.sprint)
    end

    items
  end

  def owner_backlog_menu_items_for(backlog)
    items = []

    if Cards::TaskboardCards.selected_label.present?
      items << link_to(l(:label_product_cards),
                       :controller => 'rb_stories',
                       :action => 'index',
                       :project_id => @project,
                       :format => :pdf)
    end

    items
  end
end
