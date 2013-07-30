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

module MeetingNavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name
    when /^the (\w+?) activity page for the [pP]roject "(.+?)"$/
      project = get_project($2)
      "/projects/#{project.identifier}/activity?show_#{$1}=1"
    when /^the edit page of the meeting called "(.+?)"$/
      meeting = Meeting.find_by_title($1)

      "/meetings/#{meeting.id}/edit"
    when /^the show page (?:of|for) the meeting called "(.+?)"$/
      meeting = Meeting.find_by_title($1)

      "/meetings/#{meeting.id}"
    when /^the edit page (?:of|for) the meeting called "(.+?)"$/
      meeting = Meeting.find_by_title($1)

      "/meetings/#{meeting.id}/edit"
    else
      super
    end
  end
end

World(MeetingNavigationHelpers)
