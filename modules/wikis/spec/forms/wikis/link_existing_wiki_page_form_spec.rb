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

require "spec_helper"

RSpec.describe Wikis::LinkExistingWikiPageForm, type: :forms do
  include Rails.application.routes.url_helpers

  include_context "with rendered form"

  let(:model) { build_stubbed(:relation_wiki_page_link) }

  it "renders the link attributes as hidden fields", :aggregate_failures do
    expect(page).to have_field("wikis_relation_page_link[provider_id]", type: :hidden, with: model.provider_id)
    expect(page).to have_field("wikis_relation_page_link[linkable_type]", type: :hidden, with: model.linkable_type)
    expect(page).to have_field("wikis_relation_page_link[linkable_id]", type: :hidden, with: model.linkable_id)
  end

  it "renders the wiki page selection", :aggregate_failures do
    expect(page).to have_selector :fieldset, "Wiki page"
    expect(page).to have_element :"filterable-tree-view",
                                 src: search_wiki_pages_path(provider_id: model.provider_id,
                                                             name: "wiki_page_selection")
    expect(page).to have_field "Filter", type: :search, placeholder: "Search for a wiki page"
  end
end
