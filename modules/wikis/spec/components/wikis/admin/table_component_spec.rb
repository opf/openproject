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

RSpec.describe Wikis::Admin::TableComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(rows: wiki_providers)) }

  shared_examples_for "rendering Wiki Provider Table headings" do
    include_examples "rendering Border Box Grid heading", text: "Name"
    include_examples "rendering Border Box Grid heading", text: "Provider"
    include_examples "rendering Border Box Grid heading", text: "Created"
    include_examples "rendering Border Box Grid mobile heading", text: "External wiki providers"
  end

  context "with no wiki providers" do
    let(:wiki_providers) { [] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Wiki Provider Table headings"
    it_behaves_like "rendering Blank Slate", heading: "You don't have any wiki providers set up yet.", icon: :browser
  end

  context "with wiki providers" do
    let(:xwiki_provider) { create(:xwiki_provider) }
    let(:wiki_providers) { [xwiki_provider] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Wiki Provider Table headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 1, col_count: 3

    it "renders the provider name and url" do
      expect(rendered_component).to have_css(".Box-row", text: xwiki_provider.name)
      expect(rendered_component).to have_css(".Box-row", text: xwiki_provider.url)
    end
  end
end
