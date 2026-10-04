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
  module Settings
    module Backlogs
      class EstimationUnitForm < ApplicationForm
        form do |f|
          f.hidden(name: :estimation_unit, value: model.estimation_unit)

          f.radio_button_group(
            name: :estimation_unit,
            label: ""
          ) do |group|
            group_radio_button(group, unit: Project::BACKLOGS_UNIT_STORY_POINTS)

            group_radio_button(group, unit: Project::BACKLOGS_UNIT_TIME)

            group_radio_button(group, unit: Project::BACKLOGS_UNIT_NONE)
          end

          f.submit(
            name: :submit,
            label: I18n.t("button_save"),
            scheme: :primary
          )
        end

        private

        def group_radio_button(group,
                               unit:,
                               caption: sharing_option_caption(unit),
                               &)
          group.radio_button(
            label: sharing_option_label(unit),
            value: unit,
            caption:,
            &
          )
        end

        def sharing_option_caption(option)
          sharing_option_text(option, :caption)
        end

        def sharing_option_label(option)
          sharing_option_text(option, :label)
        end

        def sharing_option_text(option, key, **)
          I18n.t("projects.settings.backlog_estimation_unit.options.#{option}.#{key}", **)
        end
      end
    end
  end
end
