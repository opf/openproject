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

module Projects
  module Types
    class BaseService < ::BaseServices::BaseContracted
      def initialize(user:, model:, contract_class: Projects::ManageTypesContract)
        super(user:, contract_class:)
        self.model = model
      end

      private

      def failure(error, **)
        model.errors.add(:types, error, **)
        ServiceResult.failure(result: model, errors: model.errors)
      end

      # TypeVariant#custom_fields resolves the form configuration link, so a variant inheriting
      # its configuration contributes the fields it actually shows rather than the none it owns.
      # Joining custom_fields_types on the variant's own id would activate nothing for it,
      # leaving the work package form empty.
      def enable_work_package_custom_fields(variant)
        model.work_package_custom_field_ids |= variant.custom_fields.ids
      end
    end
  end
end
