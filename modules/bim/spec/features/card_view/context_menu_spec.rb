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

require "spec_helper"
require_relative "../../../../../spec/features/work_packages/table/context_menu/context_menu_shared_examples"
require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "Work Package table hierarchy and sorting", :js, with_config: { edition: "bim" } do
  shared_let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking costs]) }

  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }

  shared_let(:work_package) do
    create(:work_package,
           project:,
           subject: "Parent")
  end

  shared_let(:wp_child1) do
    create(:work_package,
           project:,
           parent: work_package,
           subject: "WP child 1")
  end

  shared_let(:wp_child2) do
    create(:work_package,
           project:,
           parent: work_package,
           subject: "WP child 2")
  end
  shared_let(:menu) { Components::WorkPackages::ContextMenu.new }

  shared_current_user { create(:admin) }

  it "does not show indentation context in card view" do
    wp_table.visit!
    loading_indicator_saveguard
    wp_table.expect_work_package_listed(work_package, wp_child1, wp_child2)

    wp_table.switch_view "Cards"
    expect(page).to have_test_selector("op-wp-single-card", count: 3)

    # Expect indent-able for none
    hierarchy.expect_indent(work_package, indent: false, outdent: false, card_view: true)
    hierarchy.expect_indent(wp_child1, indent: false, outdent: false, card_view: true)
    hierarchy.expect_indent(wp_child2, indent: false, outdent: false, card_view: true)
  end

  it_behaves_like "provides a single WP context menu" do
    let(:open_context_menu) do
      -> {
        # Go to table
        wp_table.visit!
        loading_indicator_saveguard

        wp_table.expect_work_package_listed(work_package)

        wp_table.switch_view "Cards"
        loading_indicator_saveguard

        # Open context menu
        menu.expect_closed
        menu.open_for(work_package, card_view: true)
      }
    end
  end
end
