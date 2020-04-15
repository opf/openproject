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

def initialize_story_params(project, user = User.current)
  data = Story.new.attributes.slice(RbStoriesController::PERMITTED_PARAMS)
  story = HashWithIndifferentAccess.new(data)
  story['type_id'] = Story.types.first

  # unsafe attributes that will not be used directly but added for your
  # convenience
  story['project_id'] = project.id
  story['author_id']  = user.id
  story['project'] = project
  story['author']  = user
  story
end

def initialize_task_params(project, story, user = User.first)
  params = HashWithIndifferentAccess.new
  params['type_id'] = Task.type
  if story
    params['version_id'] = story.version_id
    params['parent_id']        = story.id
  end
  params['status_id'] = Status.first.id

  # unsafe attributes that will not be used directly but added for your
  # convenience
  params['project_id'] = project.id
  params['author_id']  = user.id
  params['project'] = project
  params['author']  = user
  params
end

def initialize_work_package_params(project, type = Type.first, parent = nil, user = User.first)
  params = HashWithIndifferentAccess.new
  params['type_id'] = type.id
  params['parent_id']  = parent.id if parent
  params['status_id'] = Status.first.id

  # unsafe attributes that will not be used directly but added for your
  # convenience
  params['project_id'] = project.id
  params['author_id']  = user.id
  params['project'] = project
  params['author']  = user
  params
end

def initialize_impediment_params(project, sprint, user = User.first)
  params = HashWithIndifferentAccess.new(RbTasksController::PERMITTED_PARAMS)
  params['type_id'] = Task.type
  params['version_id'] = sprint.id
  params['status_id'] = Status.first.id

  # unsafe attributes that will not be used directly but added for your
  # convenience
  params['project_id'] = project.id
  params['author_id']  = user.id
  params['project'] = project
  params['author']  = user
  params
end

def task_position(task)
  p1 = task.story.tasks.select { |t| t.id == task.id }[0].rank
  p2 = task.rank
  p1.should == p2
  p1
end

def story_position(story)
  p1 = Story.sprint_backlog(story.project, story.version).detect { |s| s.id == story.id }.rank
  p2 = story.rank
  p1.should == p2

  Story.at_rank(story.project_id, story.version_id, p1).id.should == story.id
  p1
end

def logout
  visit url_for(controller: '/account', action: 'logout')
  @user = nil
end
