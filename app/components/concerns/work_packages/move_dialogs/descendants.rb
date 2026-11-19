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

module WorkPackages
  module MoveDialogs
    # Module to include for the single and bulk move dialogs.
    #
    # The dialogs provide +move_roots+ and +i18n_scope+ to use the correct set of work packages
    # as input, and the respective I18n keys. They are only rendered when
    # +has_visible_descendants?+, the controller falls through straight to the move form
    # otherwise.
    module Descendants
      extend ActiveSupport::Concern

      # MovePlanning is the module that computes the movable/immovable descendants.
      # We need this here for the preview, and WorkPackages::UpdateService later uses its own
      # inclusion to actually perform the cascade.
      include ::WorkPackages::Shared::MovePlanning

      TARGET_NAME = "move_descendants"

      private

      def move_user
        User.current
      end

      def cross_project_relations_allowed?
        Setting.cross_project_work_package_relations?
      end

      def render_descendants_choice
        render(Primer::Alpha::RadioButtonGroup.new(
                 name: "move_descendants",
                 label: description,
                 mb: 3
               )) do |group|
          group.radio_button(value: "false",
                             checked: cross_project_relations_allowed?,
                             disabled: !cross_project_relations_allowed?,
                             label: t_dialog("descendants_choice.self_only_label"),
                             caption: t_shared("descendants_choice.self_only_caption"),
                             data: cause_data)
          group.radio_button(value: "true",
                             checked: !cross_project_relations_allowed?,
                             label: t_shared("descendants_choice.with_descendants_label"),
                             caption: t_shared("descendants_choice.with_descendants_caption"),
                             data: cause_data)
        end
      end

      def render_permission_banner
        if cross_project_relations_allowed?
          render_toggleable_banner(scheme: :warning, icon: :alert, text: t_shared("permission_banner"))
        else
          render_toggleable_banner(scheme: :warning, icon: :info, text: t_shared("same_project_required_notice"))
        end
      end

      def render_toggleable_banner(scheme:, icon:, text:)
        render(
          Primer::BaseComponent.new(tag: :div, hidden: cross_project_relations_allowed?, data: effect_data)
        ) do
          render(Primer::Alpha::Banner.new(scheme:, icon:)) { text }
        end
      end

      def cause_data
        { show_when_value_selected_target: "cause", target_name: TARGET_NAME }
      end

      def effect_data
        { show_when_value_selected_target: "effect", target_name: TARGET_NAME, value: "true" }
      end

      def t_dialog(key, **)
        I18n.t("#{i18n_scope}.#{key}", **)
      end

      # Content shared verbatim between the single and bulk move dialog, so it only
      # needs to exist (and be translated) once, under work_packages.move_dialog_shared.
      def t_shared(key, **)
        I18n.t("work_packages.move_dialog_shared.#{key}", **)
      end
    end
  end
end
