# frozen_string_literal: true

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

# Helper module included in ApplicationHelper and ActionController so that
# hooks can be called in views like this:
#
#   <%= call_hook(:some_hook) %>
#   <%= call_hook(:another_hook, foo: 'bar') %>
#
# Or in controllers like:
#   call_hook(:some_hook)
#   call_hook(:another_hook, foo: 'bar')
#
# Hooks added to views will be concatenated into a string. Hooks added to
# controllers will return an array of results.
#
# Several objects are automatically added to the call context:
#
# * project => current project
# * request => Request instance
# * controller => current Controller instance
# * hook_caller => object that called the hook
#
module HookHelper
  def call_hook(hook, context = {})
    if is_a?(ActionController::Base)
      default_context = { controller: self, project: @project, request:, hook_caller: self }
      OpenProject::Hook.call_hook(hook, default_context.merge(context))
    else
      default_context = { project: @project, hook_caller: self }
      default_context[:controller] = controller if respond_to?(:controller)
      default_context[:request] = request if respond_to?(:request)
      ApplicationController.helpers.safe_join(
        OpenProject::Hook.call_hook(hook, default_context.merge(context)),
        " "
      )
    end
  end
end
