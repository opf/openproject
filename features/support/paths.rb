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
      "/rb/master_backlogs/#{project.identifier}"

    when /^the (:?overview ?)?page (?:for|of) the [pP]roject$/
      project = get_project
      path_to %Q{the overview page of the project called "#{project.name}"}

    when /^the issues index page$/
      project = get_project
      path_to %Q{the issues index page of the project called "#{project.name}"}

    when /^the burndown for "(.+?)"(?: (?:in|of) the [pP]roject "(.+?)")?$/
      project = get_project($2)
      sprint = Sprint.find_by_name_and_project_id($1, project)

      "/rb/projects/#{project.id}/burndown_charts/#{sprint.id}"

    when /^the task ?board for "(.+?)"(?: (?:in|of) the [pP]roject "(.+?)")?$/
      project = get_project($2)
      sprint = Sprint.find_by_name_and_project_id($1, project)

      # deprecated side effect to keep some old-style step definitions
      # do not depend on @sprint being set in new step definitions
      @sprint = sprint

      "/rb/taskboards/#{sprint.id}"

    when /^the scrum statistics page$/
      "/rb/statistics"

    when /^the backlogs plugin configuration page$/
      "/settings/plugin/redmine_backlogs"
    else
      super
    end
  end
end

World(BacklogsNavigationHelpers)
