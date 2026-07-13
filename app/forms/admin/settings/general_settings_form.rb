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

module Admin
  module Settings
    class GeneralSettingsForm < ApplicationForm
      extend Dry::Initializer[undefined: false]

      option :guessed_host, optional: true

      settings_form do |sf|
        sf.text_field(
          name: :app_title,
          input_width: :medium
        )

        sf.text_field(
          name: :organization_name,
          input_width: :medium
        )

        sf.text_field(
          name: :per_page_options,
          input_width: :medium
        )

        sf.text_field(
          name: :activity_days_default,
          type: :number,
          input_width: :xsmall,
          trailing_visual: {
            text: { id: "settings_activity_days_default_unit", text: I18n.t(:label_day_plural) }
          },
          aria: { describedby: "settings_activity_days_default_unit" }
        )

        sf.text_field(
          name: :host_name,
          input_width: :medium
        )

        sf.check_box(name: :cache_formatted_text)

        sf.text_area(
          name: :allowed_link_protocols,
          input_width: :medium,
          rows: 5
        )

        sf.check_box(name: :feeds_enabled)

        sf.text_field(
          name: :feeds_limit,
          type: :number,
          input_width: :xsmall
        )

        sf.text_field(
          name: :file_max_size_displayed,
          type: :number,
          input_width: :xsmall,
          trailing_visual: {
            text: { id: "settings_file_max_size_displayed_unit", text: I18n.t(:"number.human.storage_units.units.kb") }
          },
          aria: { describedby: "settings_file_max_size_displayed_unit" }
        )

        sf.text_field(
          name: :diff_max_lines_displayed,
          type: :number,
          input_width: :xsmall
        )

        sf.check_box(name: :security_badge_displayed) if OpenProject::Configuration.security_badge_displayed?
      end
    end
  end
end
