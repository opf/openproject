module RbMasterBacklogsHelper
  unloadable

  include Redmine::I18n

  def render_backlog_menu(backlog)
    items = backlog_menu_items_for(backlog)
    is_sprint = backlog.sprint_backlog?

    html = %{
      <div class="menu">
        <div class="icon ui-icon ui-icon-carat-1-s"></div>
        <ul class="items">
    }
    items.each do |item|
      item[:condition] = true unless item.has_key?(:condition)
      if item[:condition] && ( (is_sprint && item[:for] == :sprint) ||
                               (!is_sprint && item[:for] == :product) ||
                               (item[:for] == :both) )
        html += %{ <li class="item">#{item[:item]}</li> }
      end
    end
    html += %{
        </ul>
      </div>
    }
  end

  def backlog_menu_items_for(backlog)
    [
      {
        :item => "<a href='#' class='add_new_story'>New Story</a>",
        :for  => :both
      },
      {
        :item => link_to(l(:label_task_board), {
                           :controller => 'rb_taskboards',
                           :action => 'show',
                           :sprint_id => backlog.sprint }),
        :for => :sprint
      },
      {
        :item => "<a href='#' class='show_burndown_chart'>Burndown chart</a>",
        :for  => :sprint,
        :condition => backlog.sprint && backlog.sprint.has_burndown
      },
      {
        :item => link_to(l(:label_stories_tasks), {
                           :controller => 'rb_queries',
                           :action => 'show',
                           :project_id => @project,
                           :sprint_id => backlog.sprint }),
        :for => :sprint
      },
      {
        :item => link_to(l(:label_stories), {
                           :controller => 'rb_queries',
                           :action => 'show',
                           :project_id => @project }),
        :for => :product
      },
      {
        :item => link_to(l(:label_sprint_cards), {
                           :controller => 'rb_stories',
                           :action => 'index',
                           :project_id => @project,
                           :sprint_id => backlog.sprint,
                           :format => :pdf }),
        :for => :sprint,
        :condition => Cards::TaskboardCards.selected_label
      },
      {
        :item => link_to(l(:label_product_cards), {
                           :controller => 'rb_stories',
                           :action => 'index',
                           :project_id => @project,
                           :format => :pdf }),
        :for => :product
      },
      {
        :item => link_to(l(:label_wiki), {
                           :controller => 'rb_wikis',
                           :action => 'edit',
                           :project_id => @project.id,
                           :sprint_id => backlog.sprint }),
        :for => :sprint,
        :condition => @project.module_enabled?("wiki")
      }
    ]
  end
end
