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

module Admin
  module Settings
    class LanguagesSettingsForm < ApplicationForm
      include Redmine::I18n

      settings_form do |sf|
        # required since the default checkbox, although checked, is disabled and
        # thus not submitted with the Form.
        sf.hidden(
          name: "settings[available_languages][]",
          value: Setting.default_language,
          scope_name_to_model: false,
          scope_id_to_model: false
        )

        sf.check_box_group(name: :available_languages, values: available_languages)
      end

      private

      def available_languages
        all_languages
          .map { translate_language(it) }
          .sort_by(&:first)
          .map { |name, code| build_language_entry(name, code) }
      end

      def build_language_entry(name, code)
        attrs = { label_arguments: { lang: code } }

        if code == Setting.default_language
          name = I18n.t(:"settings.language_name_being_default", language_name: name)
          attrs[:disabled] = attrs[:checked] = true
        end

        [name, code, attrs]
      end
    end
  end
end
