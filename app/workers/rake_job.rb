#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++
require "rake"

##
# Invoke a rake task while loading the tasks on demand
# to ensure they are only loaded once.
module RakeJob
  attr_reader :task_name, :args

  def perform(task_name, *args)
    @task_name = task_name
    @args = args

    Rails.logger.info { "Invoking Rake task #{task_name}." }
    invoke
  end

  protected

  def invoke
    if (task = load_task)
      task.reenable
      task.invoke *args
    else
      OpenProject.logger.error { "Rake task #{task_name} not found for background job." }
    end
  end

  ##
  # Load tasks if we don't find our task
  def load_task
    Rails.application.load_rake_tasks unless task_loaded?

    task_loaded? && Rake::Task[task_name]
  end

  ##
  # Returns whether any task is loaded
  # Will raise NameError or NoMethodError depending on what of rake is (not) loaded
  def task_loaded?
    Rake::Task.task_defined?(task_name)
  end
end
