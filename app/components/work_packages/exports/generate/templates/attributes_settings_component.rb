# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module WorkPackages
  module Exports
    module Generate
      module Templates
        class AttributesSettingsComponent < BaseSettingsComponent
          TEMPLATE_ID = "attributes"

          def self.fields
            %w[footer_text page_orientation hyphenation hyphenation_language]
          end

          def footer_text
            settings[:footer_text].to_s
          end

          def footer_text_caption
            caption = I18n.t("pdf_generator.dialog.footer_center.caption")
            return caption unless show_default_hint

            "#{caption} #{I18n.t('pdf_generator.dialog.footer_center.default_hint_project_name')}"
          end

          def page_orientation
            settings[:page_orientation]
          end

          def page_orientation_options
            [
              { label: I18n.t("pdf_generator.dialog.page_orientation.options.portrait"), value: "portrait" },
              { label: I18n.t("pdf_generator.dialog.page_orientation.options.landscape"), value: "landscape" }
            ]
          end
        end
      end
    end
  end
end
