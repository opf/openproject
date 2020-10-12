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
require 'rake'

##
# Invoke a rake task while safely loading the tasks only once
# to ensure they are neither loaded nor executed twice.
module RakeJob
  attr_reader :task_name
  attr_reader :args

  def perform(task_name, *args)
    @task_name = task_name
    @args = args

    Rails.logger.info { "Invoking Rake task #{task_name}." }
    invoke
  end

  protected

  def invoke
    load_tasks!
    task.invoke *args
  end

  ##
  # Load tasks if there are none. This should only be run once in an environment
  def load_tasks!
    OpenProject::Application.load_rake_tasks unless tasks_loaded?
  end

  ##
  # Reference to the task name.
  # Will raise NameError or NoMethodError depending on what of rake is (not) loaded
  def task
    Rake::Task[task_name]
  end

  ##
  # Returns whether any task is loaded
  # Will raise NameError or NoMethodError depending on what of rake is (not) loaded
  def tasks_loaded?
    !Rake::Task.tasks.empty?
  end
end
