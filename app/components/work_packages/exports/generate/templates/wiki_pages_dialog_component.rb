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
  module Exports
    module Generate
      module Templates
        class WikiPagesDialogComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers

          attr_reader :provider_id

          def initialize(provider_id:)
            super

            @provider_id = provider_id
          end

          def dialog_id = WikiPagesFieldsComponent::DIALOG_ID

          def controller_identifier = WikiPagesFieldsComponent::STIMULUS_CONTROLLER

          def tree_view
            Primer::OpenProject::FilterableTreeView.new(
              src: helpers.search_wiki_pages_path(provider_id:, name: "wiki_page_selection"),
              filter_input_arguments: { placeholder: I18n.t("wikis.page_link_forms.search.placeholder") },
              # The tree is single select, so neither filtering to the selection nor pulling in
              # sub-items has anything to act on.
              filter_mode_control_arguments: { hidden: true },
              include_sub_items_check_box_arguments: { hidden: true },
              no_results_node_arguments: { label: I18n.t("wikis.page_link_forms.search.no_results") }
            )
          end
        end
      end
    end
  end
end
