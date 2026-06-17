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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  class InlineNewWikiPageForm < ApplicationForm
    form do |f|
      if model.final_step?
        f.hidden(name: :provider_id)
        f.hidden(name: :page_title)

        f.filterable_tree_view(
          name: "wiki_page_selection",
          label: I18n.t("wikis.page_link_forms.labels.wiki_page"),
          src: helpers.search_wiki_pages_path(provider_id: model.provider_id, name: "wiki_page_selection"),
          filter_mode_control_arguments: { hidden: true },
          filter_input_arguments: { placeholder: I18n.t("wikis.page_link_forms.search.placeholder") },
          include_sub_items_check_box_arguments: { hidden: true },
          no_results_node_arguments: { label: I18n.t("wikis.page_link_forms.search.no_results") }
        )
      else
        f.text_field(name: :page_title, label: I18n.t("wikis.page_link_forms.labels.page_title"), required: true)

        f.select_list(name: :provider_id, label: PageLink.human_attribute_name(:provider), required: true) do |list|
          Provider.visible.enabled.each do |provider|
            list.option(label: provider.name, value: provider.id)
          end
        end
      end
    end
  end
end
