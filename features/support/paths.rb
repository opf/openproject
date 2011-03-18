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

    when /^the scrum statistics page$/
      "/rb/statistics"

    else
      super
    end
  end
end

World(BacklogsNavigationHelpers)
