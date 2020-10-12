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

class Backlog
  attr_accessor :sprint
  attr_accessor :stories

  def self.owner_backlogs(project, options = {})
    options.reverse_merge!(limit: nil)

    backlogs = Sprint.apply_to(project).with_status_open.displayed_right(project).order_by_name

    stories_by_sprints = Story.backlogs(project.id, backlogs.map(&:id))

    backlogs.map { |sprint| new(stories: stories_by_sprints[sprint.id], owner_backlog: true, sprint: sprint) }
  end

  def self.sprint_backlogs(project)
    sprints = Sprint.apply_to(project).with_status_open.displayed_left(project).order_by_date

    stories_by_sprints = Story.backlogs(project.id, sprints.map(&:id))

    sprints.map { |sprint| new(stories: stories_by_sprints[sprint.id], sprint: sprint) }
  end

  def initialize(options = {})
    options = options.with_indifferent_access
    @sprint = options['sprint']
    @stories = options['stories']
    @owner_backlog = options['owner_backlog']
  end

  def updated_on
    @stories.max_by(&:updated_at).try(:updated_at)
  end

  def owner_backlog?
    !!@owner_backlog
  end

  def sprint_backlog?
    !owner_backlog?
  end
end
