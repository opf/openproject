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

require "rails_helper"

RSpec.describe WorkPackageTypes::Overview::TableComponent,
               type: :component,
               with_flag: { type_variants: true } do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { type.default_variant }

  let(:tabs) do
    [
      { name: TypesHelper::SETTINGS_TAB, path: "/overview", label: "Overview", aspect: nil },
      { name: "details", path: "/details", label: "Details", aspect: nil },
      { name: "workflow", path: "/workflow", label: "Workflows", aspect: TypeVariant::WORKFLOWS }
    ]
  end

  subject(:component) { described_class.new(variant:, tabs:) }

  before { render_inline(component) }

  it "heads the three columns" do
    expect(page).to have_role(:columnheader, text: "Settings")
    expect(page).to have_role(:columnheader, text: "Configuration mode")
    expect(page).to have_role(:columnheader, text: "Dependent types and variants")
  end

  it "gives every tab a row of its own" do
    expect(page).to have_role(:rowheader, text: "Details")
    expect(page).to have_role(:rowheader, text: "Workflows")
  end

  it "keys each row by its tab, so a caller can address one" do
    expect(page).to have_css("#overview-details")
  end

  it "does not list itself among the settings" do
    expect(page).to have_no_link("Overview")
  end
end
