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
require_module_spec_helper

RSpec.describe Wikis::Admin::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:xwiki_provider) { create(:xwiki_provider) }

  subject(:wiki_provider_row_component) do
    table = Wikis::Admin::TableComponent.new(rows: [xwiki_provider])
    described_class.new(row: xwiki_provider, table:)
  end

  before do
    render_inline(wiki_provider_row_component)
  end

  it "renders the provider name linking to its edit page" do
    expect(page).to have_link(xwiki_provider.name, href: edit_admin_settings_wiki_provider_path(xwiki_provider))
  end

  it "renders the provider url" do
    expect(page).to have_text(xwiki_provider.url)
  end

  it "renders the provider type" do
    expect(page).to have_text("XWiki")
  end
end
