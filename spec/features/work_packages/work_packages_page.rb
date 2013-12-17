class WorkPackagesPage
  include Rails.application.routes.url_helpers
  include Capybara::DSL

  def initialize(project=nil)
    @project = project
  end

  def visit_index
    visit index_path
  end

  def click_work_packages_menu_item
    find('#main-menu .work-packages').click
  end

  def select_query(query)
    visit query_path(query);
  end

  def has_selected_filter?(filter_name)
    find(".filter-fields #cb_#{filter_name}", visible: false).checked?
  end

  private

  def index_path
    @project ? project_work_packages_path(@project) : work_packages_path
  end

  def query_path(query)
    "#{index_path}?query_id=#{query.id}"
  end
end
