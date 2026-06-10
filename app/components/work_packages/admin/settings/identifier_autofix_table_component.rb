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

module WorkPackages
  module Admin
    module Settings
      class IdentifierAutofixTableComponent < OpPrimer::BorderBoxTableComponent
        columns :project, :previous_identifier, :autofixed_suggestion, :example_work_package_id
        # Project and previous identifier hold the long content; spanning two grid columns lets
        # them wrap instead of truncating, while the short handle columns stay compact.
        main_column :project, :previous_identifier
        mobile_labels :previous_identifier, :autofixed_suggestion, :example_work_package_id

        def initialize(rows:, remaining_count: 0, **)
          super(rows:, **)
          @remaining_count = remaining_count
        end

        def row_class
          IdentifierAutofixRowComponent
        end

        def mobile_title
          header(:table_title)
        end

        def headers
          [
            [:project, { caption: header(:label_project) }],
            [:previous_identifier, { caption: header(:label_previous_identifier) }],
            [:autofixed_suggestion, { caption: header(:label_autofixed_suggestion) }],
            [:example_work_package_id, { caption: header(:label_example_work_package_id) }]
          ]
        end

        def has_footer?
          @remaining_count.positive?
        end

        def footer
          I18n.t("admin.settings.work_packages_identifier.autofix_preview.remaining_projects",
                 count: @remaining_count)
        end

        private

        def header(key)
          I18n.t("admin.settings.work_packages_identifier.box_header.#{key}")
        end
      end
    end
  end
end
