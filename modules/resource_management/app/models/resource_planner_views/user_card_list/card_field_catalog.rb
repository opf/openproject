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

module ResourcePlannerViews
  module UserCardList
    # Single source of truth for the fields selectable on a user card view.
    # Drives both the configure dialog (options + currently selected) and the
    # save path (whitelist of valid identifiers).
    #
    # Identifiers are the built-in keys below plus user custom field column
    # names ("cf_<id>"). The custom field carrying the "job_title" semantic key
    # is excluded, since the job title is shown next to the user's name.
    module CardFieldCatalog
      BUILT_IN = %w[department working_times].freeze

      module_function

      # Ordered [{ id:, name: }, ...] for the draggable autocompleter options.
      def options(user: User.current)
        built_in_options + custom_field_options(user)
      end

      # Set of all valid identifiers, used to filter user-submitted ids on save.
      def allowed_ids(user: User.current)
        options(user:).to_set { |option| option[:id] }
      end

      # Maps stored ids back to [{ id:, name: }] preserving order, dropping
      # any identifier no longer present in the catalog.
      def selected_options(ids, user: User.current)
        by_id = options(user:).index_by { |option| option[:id] }
        Array(ids).filter_map { |id| by_id[id] }
      end

      def built_in_options
        [
          { id: "department", name: User.human_attribute_name(:department) },
          { id: "working_times", name: I18n.t("resource_management.user_card_list.fields.working_times") }
        ]
      end

      def custom_field_options(user)
        selectable_custom_fields(user).map { |cf| { id: cf.column_name, name: cf.name } }
      end

      def selectable_custom_fields(user)
        scope = UserCustomField.visible(user).order(:position)

        if (job_title = UserCustomField.for_semantic_key(:job_title))
          scope = scope.where.not(id: job_title.id)
        end

        scope
      end
    end
  end
end
