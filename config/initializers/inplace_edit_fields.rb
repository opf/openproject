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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Rails.application.config.to_prepare do
  # Register the edit fields per attribute
  OpenProject::InplaceEdit::FieldRegistry.register(:description, OpPrimer::InplaceEditFields::RichTextAreaComponent)
  OpenProject::InplaceEdit::FieldRegistry.register(:status_explanation, OpPrimer::InplaceEditFields::RichTextAreaComponent)

  # Register custom field edit components based on field format
  # This mirrors the pattern used in CustomFields::CustomFieldRendering
  custom_field_format_mappings = {
    "string" => OpPrimer::InplaceEditFields::TextInputComponent,
    "text" => OpPrimer::InplaceEditFields::RichTextAreaComponent,
    "int" => OpPrimer::InplaceEditFields::IntegerInputComponent,
    "float" => OpPrimer::InplaceEditFields::FloatInputComponent,
    "date" => OpPrimer::InplaceEditFields::DateInputComponent,
    "bool" => OpPrimer::InplaceEditFields::BooleanInputComponent,
    "link" => OpPrimer::InplaceEditFields::LinkInputComponent,
    "hierarchy" => OpPrimer::InplaceEditFields::HierarchyListComponent,
    "weighted_item_list" => OpPrimer::InplaceEditFields::HierarchyListComponent,
    "list" => OpPrimer::InplaceEditFields::SelectListComponent,
    "user" => OpPrimer::InplaceEditFields::UserSelectListComponent,
    "version" => OpPrimer::InplaceEditFields::VersionSelectListComponent,
    "calculated_value" => OpPrimer::InplaceEditFields::CalculatedValueInputComponent
  }

  OpenProject::InplaceEdit::FieldRegistry.register_custom_field_format_mappings(custom_field_format_mappings)

  # Register the update handler per model
  OpenProject::InplaceEdit::UpdateRegistry.register(Project,
                                                    handler: OpenProject::InplaceEdit::Handlers::ProjectUpdate,
                                                    contract: Projects::UpdateContract)
end
