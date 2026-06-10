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
  class LinkExistingWikiPageForm < ApplicationForm
    form do |f|
      f.hidden(name: :provider_id)
      f.hidden(name: :linkable_type)
      f.hidden(name: :linkable_id)

      f.html_content do
        render(
          Primer::OpenProject::FilterableTreeView.new(
            src: helpers.search_wiki_pages_path(provider_id: model.provider_id, name: "wiki_page_selection"),
            form_arguments: { builder: rails_builder(f), name: "wiki_page_selection" },
            filter_mode_control_arguments: { hidden: true },
            filter_input_arguments: {
              placeholder: I18n.t("wikis.link_existing_wiki_page_form.placeholder"),
              # every other property is just refilling the default values,
              # as those are not merged into custom arguments
              name: :filter,
              label: I18n.t(:button_filter),
              type: :search,
              leading_visual: { icon: :search },
              visually_hide_label: true,
              show_clear_button: true
            },
            include_sub_items_check_box_arguments: { hidden: true },
            no_results_node_arguments: { label: I18n.t("wikis.link_existing_wiki_page_form.no_results") }
          )
        )
      end
    end

    private

    # Primer's FormObject stores the underlying ActionView/Primer form builder
    # as @builder. FilterableTreeView requires an ActionView::FormBuilder to
    # generate its hidden form inputs via hidden_field.
    def rails_builder(form)
      form.instance_variable_get(:@builder)
    end
  end
end
