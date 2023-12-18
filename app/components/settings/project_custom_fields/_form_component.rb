#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
#
#
#
#
#
# TODO: currently not working properly when using rails partials within the template of this component
# renders <td><tr> tags as strings instead of proper HTML tags within the custom options table
# using plain rails views for form rendering for now (tbd!)
#
#
#
#
#
# module Settings
#   module ProjectCustomFields
#     class FormComponent < ApplicationComponent
#       include ApplicationHelper
#       include CustomFieldsHelper
#       include StimulusHelper
#       include ErrorMessageHelper
#       include OpenProject::FormTagHelper
#       include OpPrimer::ComponentHelpers

#       def initialize(custom_field: ProjectCustomField.new)
#         super

#         @custom_field = custom_field
#       end

#       private

#       def form_config
#         {
#           as: :custom_field,
#           url: @custom_field.persisted? ? admin_settings_project_custom_field_path(@custom_field) : admin_settings_project_custom_fields_path,
#           html: { method: @custom_field.persisted? ? :put : :post, id: 'custom_field_form' }
#         }
#       end
#     end
#   end
# end
