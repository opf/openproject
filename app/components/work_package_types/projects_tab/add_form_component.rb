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

module WorkPackageTypes
  module ProjectsTab
    class AddFormComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      DIALOG_ID = "work-package-type-add-projects-dialog"
      FORM_ID = "work-package-type-add-projects-form"
      FIELD_NAME = "project_ids"

      def initialize(variant:, validation_message: nil)
        super()

        @variant = variant
        @validation_message = validation_message
      end

      def form_arguments
        {
          id: FORM_ID,
          url: url_helpers.link_type_projects_path(**variant.path_args),
          method: :post,
          data: { turbo: true }
        }
      end

      private

      attr_reader :variant, :validation_message

      def tree_src = url_helpers.tree_type_projects_path(**variant.path_args, name: FIELD_NAME)
    end
  end
end
