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

require "rails_helper"

RSpec.describe Admin::SettingsSearchComponent, type: :component do
  let(:node) { Settings::SearchTree::Node }
  let(:nodes) do
    [
      node.new(key: "settings", label: "System settings", description: nil, href: "/admin/settings/general", children: [
                 node.new(key: "general-app_title", label: "Application title", description: "Shown in the header",
                          href: "/admin/settings/general?highlight=app_title", children: [])
               ])
    ]
  end
  let(:tree) { instance_double(Settings::SearchTree, nodes:) }

  subject(:rendered_component) do
    render_inline(described_class.new(tree:))
    page
  end

  it "renders the menu hierarchy with settings as links", :aggregate_failures do
    expect(rendered_component).to have_button "Search settings"
    expect(rendered_component).to have_link "System settings", href: "/admin/settings/general", visible: :all
    expect(rendered_component).to have_link "Application title", href: "/admin/settings/general?highlight=app_title",
                                                                 visible: :all
  end

  it "includes the description as searchable, visually hidden text" do
    expect(rendered_component).to have_css(".sr-only", text: "Shown in the header", visible: :all)
  end

  context "without any nodes" do
    let(:nodes) { [] }

    it "renders nothing" do
      expect(rendered_component).to have_no_css("*")
    end
  end
end
