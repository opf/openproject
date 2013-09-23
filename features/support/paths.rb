module BacklogsNavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /^the master backlog(?: of the [pP]roject "(.+?)")?$/
      project = get_project($1)
      "/projects/#{project.identifier}/backlogs"

    when /^the (:?overview ?)?page (?:for|of) the [pP]roject$/
      project = get_project
      path_to %Q{the overview page of the project called "#{project.name}"}

    when /^the work_packages index page$/
      project = get_project
      path_to %Q{the work_packages index page of the project called "#{project.name}"}

    when /^the burndown for "(.+?)"(?: (?:in|of) the [pP]roject "(.+?)")?$/
      project = get_project($2)
      sprint = Sprint.find_by_name_and_project_id($1, project)

      "/projects/#{project.identifier}/sprints/#{sprint.id}/burndown_chart"

    when /^the task ?board for "(.+?)"(?: (?:in|of) the [pP]roject "(.+?)")?$/
      project = get_project($2)
      sprint = Sprint.find_by_name_and_project_id($1, project)

      # deprecated side effect to keep some old-style step definitions
      # do not depend on @sprint being set in new step definitions
      @sprint = sprint

      "/projects/#{project.identifier}/sprints/#{sprint.id}/taskboard"

    else
      super
    end
  end
end

World(BacklogsNavigationHelpers)
