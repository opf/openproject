#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

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
      path_to %{the overview page of the project called "#{project.name}"}

    when /^the work_packages index page$/
      project = get_project
      path_to %{the work packages index page of the project called "#{project.name}"}

    when /^the burndown for "(.+?)"(?: (?:in|of) the [pP]roject "(.+?)")?$/
      project = get_project($2)
      sprint = Sprint.find_by(name: $1, project: project)

      "/projects/#{project.identifier}/sprints/#{sprint.id}/burndown_chart"

    when /^the task ?board for "(.+?)"(?: (?:in|of) the [pP]roject "(.+?)")?$/
      project = get_project($2)
      sprint = Sprint.find_by(name: $1, project: project)

      # WARN: Deprecated side effect to keep some old-style step definitions.
      #       Do not depend on @sprint being set in new step definitions.
      @sprint = sprint

      "/projects/#{project.identifier}/sprints/#{sprint.id}/taskboard"

    else
      super
    end
  end
end

World(BacklogsNavigationHelpers)
