module ProjectPageNavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /^the project "(.+)" overview personalization page$/
      project = Project.find_by_name($1)
      "/my_projects_overview/#{project.identifier}/page_layout"
    when /^the project "(.+)" overview page$/
      project = Project.find_by_name($1)
      "/projects/#{project.identifier}"
    else
      super
    end
  end
end

World(ProjectPageNavigationHelpers)
