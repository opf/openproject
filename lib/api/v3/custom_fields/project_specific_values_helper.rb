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

module API
  module V3
    module CustomFields
      module ProjectSpecificValuesHelper
        # Returns nil if every value of the custom field is visible.
        def visible_value_ids(custom_field)
          project = requested_project
          return if custom_field.project_specific_value_restriction.nil?

          values = project ? custom_field.usable_values_in(project) : custom_field.visible_values_for(current_user)
          values.pluck(:id).to_set
        end

        def hidden_value?(value, visible_ids)
          !visible_ids.nil? && visible_ids.exclude?(value.id)
        end

        private

        def requested_project
          return if params[:project].blank?

          Project.allowed_to(current_user, :view_work_packages).find_by(id: params[:project]) ||
            raise(::API::Errors::NotFound)
        end
      end
    end
  end
end
