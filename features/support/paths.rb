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

# TL;DR: YOU SHOULD DELETE THIS FILE
#
# This file is used by web_steps.rb, which you should also delete
#
# You have been warned
module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /^the home\s?page$/
      '/'

    when /^the login page$/
      '/login'

    when /^the [wW]iki [pP]age "([^\"]+)" (?:for|of) the project called "([^\"]+)"$/
      wiki_page = Wiki.titleize($1)
      project_identifier = $2.gsub("\"", "")
      project = Project.find_by_name(project_identifier)
      project_identifier = project.identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}/wiki/#{wiki_page}"

    when /^the edit menu item page of the [wW]iki [pP]age "([^\"]+)" (?:for|of) the project called "([^\"]+)"$/
      wiki_page = Wiki.titleize($1)
      project_identifier = $2.gsub("\"", "")
      project = Project.find_by_name(project_identifier)
      project_identifier = project.identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}/wiki/#{wiki_page}/wiki_menu_item/edit"

    when /^the [cC]ost [rR]eports page (?:of|for) the project called "([^\"]+)" without filters or groups$/
      project_identifier = Project.find_by_name($1).identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}/cost_reports?set_filter=1"

    when /^the [cC]ost [rR]eports page (?:of|for) the project called "([^\"]+)"$/
      project_identifier = Project.find_by_name($1).identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}/cost_reports"

    when /^the overall [cC]ost [rR]eports page$/
      "/cost_reports"

    when /^the overall [cC]ost [rR]eports page without filters or groups$/
      "/cost_reports?set_filter=1"

    when /^the overall [cC]ost [rR]eports page with standard groups in debug mode$/
      "/cost_reports?set_filter=1&groups[columns][]=cost_type_id&groups[rows][]=user_id&debug=1"

    when /^the overall [cC]ost [rR]eports page with standard groups$/
      "/cost_reports?set_filter=1&groups[columns][]=cost_type_id&groups[rows][]=user_id"

    when /^the overall [pP]rojects page$/
      "/projects"

    when /^the (?:(?:overview |home ?))?page (?:for|of) the project(?: called)? "(.+)"$/
      project_identifier = $1.gsub("\"", "")
      project_identifier = Project.find_by_name(project_identifier).identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}"

    when /^the activity page of the project(?: called)? "(.+)"$/
      project_identifier = $1.gsub("\"", "")
      project_identifier = Project.find_by_name(project_identifier).identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}/activity"

    when /^the overall activity page$/
      "/activity"

    when /^the page (?:for|of) the issue "([^\"]+)"$/
      issue = Issue.find_by_subject($1)
      "/work_packages/#{issue.id}"

    when /^the edit page (?:for|of) the issue "([^\"]+)"$/
      issue = Issue.find_by_subject($1)
      "/issues/#{issue.id}/edit"

    when /^the copy page (?:for|of) the issue "([^\"]+)"$/
      issue = Issue.find_by_subject($1)
      project = issue.project
      "/projects/#{project.identifier}/issues/#{issue.id}/copy"

    when /^the issues? index page (?:for|of) (the)? project(?: called)? (.+)$/
       project_identifier = $2.gsub("\"", "")
       project_identifier = Project.find_by_name(project_identifier).identifier.gsub(' ', '%20')
       "/projects/#{project_identifier}/issues"

    when /^the page (?:for|of) the work package(?: called)? "([^\"]+)"$/
      work_package = WorkPackage.find_by_subject($1)
      "/work_packages/#{work_package.id}"

    when /^the new work_package page (?:for|of) the project called "([^\"]+)"$/
      "/projects/#{$1}/work_packages/new"

    when /^the wiki index page(?: below the (.+) page)? (?:for|of) (?:the)? project(?: called)? (.+)$/
       parent_page_title, project_identifier = $1, $2
       project_identifier.gsub!("\"", "")
       project_identifier = Project.find_by_name(project_identifier).identifier.gsub(' ', '%20')

       if parent_page_title.present?
         parent_page_title.gsub!("\"", "")

        "/projects/#{project_identifier}/wiki/#{parent_page_title}/toc"
       else
        "/projects/#{project_identifier}/wiki/index"
       end

    when /^the wiki new child page below the (.+) page (?:for|of) (?:the)? project(?: called)? (.+)$/
       parent_page_title, project_identifier = $1, $2
       project_identifier.gsub!("\"", "")
       parent_page_title.gsub!("\"", "")
       project_identifier = Project.find_by_name(project_identifier).identifier.gsub(' ', '%20')

       "/projects/#{project_identifier}/wiki/#{parent_page_title}/new"

    when /^the edit page (?:for |of )(the )?role(?: called)? (.+)$/
      role_identifier = $2.gsub("\"", "")
      role_identifier = Role.find_by_name(role_identifier).id
      "/roles/edit/#{role_identifier}"

    when /^the edit page (?:for |of )(the )?user(?: called)? (.+)$/
      user_identifier = $2.gsub("\"", "")
      user_identifier = User.find_by_login(user_identifier).id
      "/users/#{user_identifier}/edit"

    when /^the show page (?:for |of )(the )?user(?: called)? (.+)$/
      user_identifier = $2.gsub("\"", "")
      user_identifier = User.find_by_login(user_identifier).id
      "/users/#{user_identifier}"

    when /^the index page (?:for|of) users$/
      "/users"

    when /^the global index page (?:for|of) (.+)$/
      "/#{$1}"

    when /^the edit page (?:for |of )the version(?: called) (.+)$/
      version_name = $1.gsub("\"", "")
      version = Version.find_by_name(version_name)
      "/versions/edit/#{version.id}"

    # this should be handled by the generic "the edit page of ..." path
    # but the path required differs from the standard
    # delete once the path is corrected
    when /the edit page (?:for |of )the (?:issue )?custom field(?: called) (.+)/
      name = $1.gsub("\"", "")
      instance = InstanceFinder.find(CustomField, name)
      "/custom_fields/edit/#{instance.id}"

    when /^the new page (?:for|of) (.+)$/
      model = $1.gsub!("\"", "").downcase
      "/#{model.pluralize}/new"

    when /^the edit page of the group called "([^\"]+)"$/
      identifier = $1.gsub("\"", "")
      instance = InstanceFinder.find(Group, identifier)
      "/admin/groups/#{instance.id}/edit"

    when /^the edit page (?:for|of) (?:the )?([^\"]+?)(?: called)? "([^\"]+)"$/
      model, identifier = $1, $2
      identifier.gsub!("\"", "")
      model = model.gsub("\"", "").gsub(/\s/, "_")

      begin
        instance = InstanceFinder.find(model.camelize.constantize, identifier)
      rescue NameError
        instance = InstanceFinder.find(model.to_sym, identifier)
      end

      root = RouteMap.route(instance.class)

      "#{root}/#{instance.id}/edit"

    when /^the log ?out page$/
      '/logout'

    when /^the (register|registration) page$/
      '/account/register'

    when /^the activate registration page for the user called (.+) with (.+)$/
      name = $1.dup
      selection = $2.dup
      name.gsub!("\"","")
      selection.gsub!("\"","")
      u = User.find_by_login(name)
      "/account/#{u.id}/activate?#{selection}"

    when /^the My page$/
      '/my/page'

    when /^the [mM]y account page$/
      '/my/account'

    when /^the (administration|admin) page$/
      '/admin'

    when /^the(?: (.+?) tab of the)? settings page$/
      if $1.nil?
        "/settings"
      else
        "/settings/edit?tab=#{$1}"
      end

    when /^the(?: (.+?) tab of the)? settings page (?:of|for) the project "(.+?)"$/
      if $1.nil?
        "/projects/#{$2}/settings"
      else
        "/projects/#{$2}/settings/#{$1}"
      end

    when /^the edit page of Announcement$/
      '/announcements/1/edit'

    when /^the index page of Roles$/
      '/roles'

    when /^the search page$/
      '/search'

    when /^the custom fields page$/
      '/custom_fields'

    when /^the enumerations page$/
      '/admin/enumerations'

    when /^the authentication modes page$/
      '/auth_sources'

    when /the page of the timeline(?: "([^\"]+)")? of the project called "([^\"]+)"$/
      timeline_name = $1
      project_name = $2
      project_identifier = Project.find_by_name(project_name).identifier.gsub(' ', '%20')
      timeline = Timeline.find_by_name(timeline_name)

      timeline_id = timeline ?
                      "/#{timeline.id}" :
                      ""

      "/projects/#{project_identifier}/timelines#{timeline_id}"

    when /the new timeline page of the project called "([^\"]+)"$/
      project_name = $1
      project_identifier = Project.find_by_name(project_name).identifier.gsub(' ', '%20')

      "/projects/#{project_identifier}/timelines/new"

    when /the edit page of the timeline "([^\"]+)" of the project called "([^\"]+)"$/
      timeline_name = $1
      project_name = $2
      project_identifier = Project.find_by_name(project_name).identifier.gsub(' ', '%20')
      timeline = Timeline.find_by_name(timeline_name)
      "/projects/#{project_identifier}/timelines/#{timeline.id}/edit"

    when /^the page of the planning element "([^\"]+)" of the project called "([^\"]+)"$/
      planning_element_name = $1
      planning_element = PlanningElement.find_by_subject(planning_element_name)
      "/work_packages/#{planning_element.id}"

    when /^the (.+) page (?:for|of) the project called "([^\"]+)"$/
      project_page = $1
      project_identifier = $2.gsub("\"", "")
      project_page = project_page.gsub(' ', '').underscore
      project_identifier = Project.find_by_name(project_identifier).identifier.gsub(' ', '%20')
      "/projects/#{project_identifier}/#{project_page}"

    when /^the quick reference for wiki syntax$/
      "/help/wiki_syntax"

    when /^the detailed wiki syntax help page$/
      "/help/wiki_syntax_detailed"

    when /^the configuration page of the "(.+)" plugin$/
      "/settings/plugin/#{$1}"

    when /^the admin page of the group called "([^"]*)"$/
      id = Group.find_by_lastname!($1).id
      "/admin/groups/#{id}/edit"

    when /^the time entry page of issue "(.+)"$/
      issue_id = Issue.find_by_subject($1).id
      "/issues/#{issue_id}/time_entries"

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))
    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
