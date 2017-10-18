#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'date'

class Task < WorkPackage
  extend OpenProject::Backlogs::Mixins::PreventIssueSti

  def self.type
    task_type = Setting.plugin_openproject_backlogs['task_type']
    task_type.blank? ? nil : task_type.to_i
  end

  # This method is used by Backlogs::List. It ensures, that tasks and stories
  # follow a similar interface
  def self.types
    [type]
  end

  def self.create_with_relationships(params, project_id)
    prev = params.delete(:prev)
    if task = create_with_relationships_without_move(params, project_id)
      task.move_after prev
    end

    task
  end

  def self.tasks_for(story_id)
    Task.children_of(story_id).order(:position).each_with_index do |task, i|
      task.rank = i + 1
    end
  end

  def status_id=(id)
    super
    self.remaining_hours = 0 if Status.find(id).is_closed?
  end

  def update_with_relationships(params, _is_impediment = false)
    prev = params.delete(:prev)
    update_with_relationships_without_move(params).tap do |result|
      move_after(prev) if result
    end
  end

  def rank=(r)
    @rank = r
  end

  def self.create_with_relationships_without_move(params, project_id)
    # Important, otherwise attributes= fails with unknown attribute error.
    _prev = params.delete(:prev)

    task = new

    task.author = User.current
    task.project_id = project_id
    task.type_id = Task.type

    task.attributes = params

    task.save

    task
  end

  def update_with_relationships_without_move(params)
    prev = params.delete(:prev)
    self.attributes = params

    save
  end

  attr_reader :rank
end
