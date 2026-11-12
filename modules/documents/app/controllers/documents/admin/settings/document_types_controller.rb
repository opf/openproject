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

module Documents
  module Admin
    module Settings
      class DocumentTypesController < ::Admin::Settings::EnumerationsControllerBase
        menu_item :document_types

        def delete_dialog
          find_enumeration
          respond_with_dialog(
            if @enumeration.only_remaining_record?
              Documents::Admin::DocumentTypes::CannotDeleteLastDialogComponent.new
            else
              Documents::Admin::DocumentTypes::DeleteDialogComponent.new(@enumeration)
            end
          )
        end

        private

        def enumeration_class
          DocumentType
        end

        def index_component_class
          ::Documents::Admin::DocumentTypes::IndexComponent
        end
      end
    end
  end
end
