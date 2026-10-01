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

Rails.application.config.to_prepare do
  # Register the edit fields per attribute
  OpenProject::InplaceEdit::FieldRegistry.register(:description, OpenProject::Common::InplaceEditFields::RichTextAreaComponent)
  OpenProject::InplaceEdit::FieldRegistry.register(:status_explanation, OpenProject::Common::InplaceEditFields::RichTextAreaComponent)

  # Register custom field edit components based on field format
  # This mirrors the pattern used in CustomFields::CustomFieldRendering
  custom_field_format_mappings = {
    "string" => OpenProject::Common::InplaceEditFields::TextInputComponent,
    "text" => OpenProject::Common::InplaceEditFields::RichTextAreaComponent,
    "int" => OpenProject::Common::InplaceEditFields::IntegerInputComponent,
    "float" => OpenProject::Common::InplaceEditFields::FloatInputComponent,
    "date" => OpenProject::Common::InplaceEditFields::DateInputComponent,
    "bool" => OpenProject::Common::InplaceEditFields::BooleanInputComponent,
    "link" => OpenProject::Common::InplaceEditFields::LinkInputComponent,
    "hierarchy" => OpenProject::Common::InplaceEditFields::HierarchyListComponent,
    "weighted_item_list" => OpenProject::Common::InplaceEditFields::HierarchyListComponent,
    "list" => OpenProject::Common::InplaceEditFields::SelectListComponent,
    "user" => OpenProject::Common::InplaceEditFields::UserSelectListComponent,
    "version" => OpenProject::Common::InplaceEditFields::VersionSelectListComponent,
    "calculated_value" => OpenProject::Common::InplaceEditFields::CalculatedValueInputComponent
  }

  OpenProject::InplaceEdit::FieldRegistry.register_custom_field_format_mappings(custom_field_format_mappings)

  # Register the update handler per model
  OpenProject::InplaceEdit::UpdateRegistry.register(Project,
                                                    handler: OpenProject::InplaceEdit::Handlers::ProjectUpdate,
                                                    contract: Projects::UpdateContract)
end
