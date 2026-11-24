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

module Projects::Settings::WorkPackages::SecurityLevels
  class Form < ApplicationForm
    form do |f|
      f.select_list(
        name: :security_level_scheme_id,
        label: SecurityLevelScheme.model_name.human,
        caption: I18n.t("settings.work_packages.security_levels.scheme_caption"),
        include_blank: I18n.t("settings.work_packages.security_levels.no_scheme"),
        input_width: :large
      ) do |list|
        SecurityLevelScheme.order(:name).each do |scheme|
          list.option(label: scheme.name, value: scheme.id, selected: scheme.id == model.security_level_scheme_id)
        end
      end

      f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
    end

    def initialize(**_options)
      super()
    end
  end
end
