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
  module DeleteDialogs
    # Module to include for the bulk and single delete dialogs.
    # They take care of previewing the deletion of visible work packages, and filtering them.
    #
    # The dialogs provide +deletion_roots+ and +i18n_scope+ to use the correct set of work packages
    # as input, and the respective I18n keys.
    module Descendants
      extend ActiveSupport::Concern

      # DeletionPlanning is the module that computes the work packages
      # and puts them into the categories deletable/unlinked.
      # We need this here for the preview and the DeleteService later, so it's another separate module.
      include ::WorkPackages::Shared::DeletionPlanning

      private

      def deletion_user
        User.current
      end

      # The dialogs always show the full cascade, the user's actual choice is applied later by
      # WorkPackages::DeleteService.
      def include_descendants?
        true
      end

      def render_descendants_choice
        render(Primer::Alpha::RadioButtonGroup.new(
                 name: "delete_descendants",
                 label: t_dialog("descendants_choice.heading"),
                 visually_hide_label: true,
                 mb: 3
               )) do |group|
          group.radio_button(value: "false",
                             label: t_dialog("descendants_choice.self_only_label"),
                             caption: t_dialog("descendants_choice.self_only_caption"))
          group.radio_button(value: "true",
                             checked: true,
                             label: t_dialog("descendants_choice.with_descendants_label"),
                             caption: t_dialog("descendants_choice.with_descendants_caption"))
        end
      end

      def variant
        @variant ||=
          if !has_descendants? then :none
          elsif !unlinked_descendants? then :all
          elsif visible_unlinked_descendants.none? then :hidden
          else :undeletable
          end
      end

      def has_descendants?
        deleted_descendants.any? || unlinked_descendants?
      end

      def nothing_deleted?
        deleted_descendants.none?
      end

      def hidden_warning_key
        nothing_deleted? ? "hidden_descendants_only_warning" : "hidden_descendants_warning"
      end

      def undeletable_warning_key
        base = "undeletable_descendants_warning"

        hidden_unlinked_count.zero? ? "#{base}_html" : base
      end

      def undeletable_count
        unlinked_descendants.size
      end

      # Filter the visible descendants to gather the project names,
      # as we cannot show any other projects the user has no access to.
      def undeletable_project_links
        link_to_projects(visible_unlinked_descendants.filter_map(&:project).uniq)
      end

      def link_to_projects(projects)
        safe_join(projects.map { |project| helpers.link_to(project.name, helpers.project_path(project)) }, ", ")
      end

      def t_dialog(key, **)
        I18n.t("#{i18n_scope}.#{key}", **)
      end
    end
  end
end
