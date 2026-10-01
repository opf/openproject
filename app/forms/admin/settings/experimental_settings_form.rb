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
    class ExperimentalSettingsForm < ApplicationForm
      include ::Settings::FormHelper

      settings_form do |sf|
        sf.check_box_group(
          label: I18n.t("settings.experimental.feature_flags"),
          visually_hide_label: true
        ) do |group|
          available_feature_flags.each do |(label, name)|
            next if !setting_value(name) && setting_disabled?(name)

            group.check_box(
              name:,
              label:,
              checked: setting_value(name),
              disabled: setting_disabled?(name),
              caption: ::Settings::Definition[name].description
            )
          end
        end
      end

      private

      def available_feature_flags
        OpenProject::FeatureDecisions
          .all
          .map { [it.to_s.humanize, "feature_#{it}_active"] }
      end
    end
  end
end
