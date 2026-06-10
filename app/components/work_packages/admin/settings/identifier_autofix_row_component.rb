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
      class IdentifierAutofixRowComponent < OpPrimer::BorderBoxRowComponent
        def project
          render(Primer::Beta::Link.new(href: project_path(model[:project]))) { model[:project].name }
        end

        def previous_identifier
          flex_layout(direction: :column) do |col|
            col.with_row { render(Primer::Beta::Text.new) { model[:current_identifier] } }
            if (label = error_label).present?
              col.with_row do
                render(Primer::OpenProject::InlineMessage.new(scheme: :critical, size: :small)) { label }
              end
            end
          end
        end

        def autofixed_suggestion
          model[:suggested_identifier]
        end

        # The sequence number is derived deterministically from the identifier so it looks
        # varied across projects but is stable across renders. Range: 1–500.
        def example_work_package_id
          identifier = model[:suggested_identifier]
          "#{identifier}-#{(identifier.bytes.sum % 500) + 1}"
        end

        private

        def error_label
          I18n.t("admin.settings.work_packages_identifier.autofix_preview.error_#{model[:error_reason]}",
                 default: "")
        end
      end
    end
  end
end
