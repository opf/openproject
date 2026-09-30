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

require "spec_helper"

RSpec.describe "Paginated type ordering", :js, :selenium,
               with_settings: { per_page_options: "2,100" } do
  shared_let(:admin) { create(:admin) }
  shared_let(:types) { %w[A B C D E].map { |name| create(:type, name:) } }

  let(:index_page) { Pages::Types::Index.new }

  before { login_as(admin) }

  def drag(name, before:)
    wait_for_turbo_stream { index_page.drag(name, before:) }
  end

  it "reorders twice on page two across morphs and persists on reload" do
    visit types_path(page: 2, per_page: 2)
    index_page.expect_page_order("C", "D")

    drag("D", before: "C")
    index_page.expect_page_order("D", "C")
    index_page.expect_db_order("A", "B", "D", "C", "E")

    drag("C", before: "D")
    index_page.expect_page_order("C", "D")
    index_page.expect_db_order("A", "B", "C", "D", "E")

    page.refresh
    index_page.expect_page_order("C", "D")
    expect(page).to have_current_path(types_path(page: 2, per_page: 2))
  end

  it "moves expanded groups without mixing their variants or matching nested rows" do
    Type.find_by!(name: "C").update!(name: "Bug")
    Type.find_by!(name: "D").update!(name: "Bugfix")
    bug = Type.find_by!(name: "Bug")
    zeta = create(:type_variant, type: bug, variant_name: "Zeta")
    alpha = create(:type_variant, type: bug, variant_name: "Alpha")
    visit types_path(page: 2, per_page: 2, expand: bug.id)
    index_page.expect_page_order("Bug", "Bugfix")

    drag("Bugfix", before: "Bug")
    index_page.expect_page_order("Bugfix", "Bug")
    index_page.expect_db_order("A", "B", "Bugfix", "Bug", "E")
    within(index_page.type_group("Bug")) do
      expect(page).to have_link("Alpha")
      expect(page).to have_link("Zeta")
    end
    expect(bug.variants.non_default_variants.in_display_order).to eq([alpha, zeta])
  end
end
