#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Projects::Concerns
  module ResetGlobalQueryHooks
    private

    def after_validate(params, service_call)
      # we need to reset the query_available_custom_fields_on_global_level already after validation
      # as the update service just calls .valid? and returns if invalid
      # after_save is not touched in this case which causes the flag to stay active
      set_query_available_custom_fields_to_project_level(service_call.result)

      super
    end

    def after_perform(service_call)
      set_query_available_custom_fields_to_project_level(service_call.result)

      super
    end

    def set_query_available_custom_fields_to_project_level(model)
      # reset the query_available_custom_fields_on_global_level after saving
      # in order not to silently carry this setting in this instance
      model._query_available_custom_fields_on_global_level = nil
    end
  end
end
