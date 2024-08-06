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

RSpec.describe "Update ancestors", :js, :with_cuprite do
  shared_let(:user) { create(:admin) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:new_status) { create(:default_status, name: "New") }
  shared_let(:closed_status) { create(:closed_status, name: "Closed") }
  shared_let(:type) { create(:type_task) }
  shared_let(:project_role) { create(:project_role) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:workflows) do
    create(:workflow,
           type_id: type.id,
           old_status: new_status,
           new_status: closed_status,
           role: project_role)

    create(:workflow,
           type_id: type.id,
           old_status: closed_status,
           new_status:,
           role: project_role)
  end

  before_all do
    set_factory_default(:priority, priority)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, new_status)
    set_factory_default(:type, type)
    set_factory_default(:user, user)
  end

  shared_let(:parent) do
    create(:work_package,
           subject: "parent",
           estimated_hours: 2,
           remaining_hours: 1)
  end
  shared_let(:child) do
    create(:work_package,
           parent:,
           subject: "child",
           estimated_hours: 6,
           remaining_hours: 3,
           done_ratio: 50)
  end
  shared_let(:second_child) do
    create(:work_package,
           parent:,
           subject: "second child",
           estimated_hours: 3,
           remaining_hours: 3,
           done_ratio: 0)
  end
  shared_let(:query) do
    create(:query,
           show_hierarchies: true,
           column_names: %i[id status estimated_hours remaining_hours done_ratio subject])
  end

  let(:wp_table) { Pages::WorkPackagesTable.new project }

  before do
    # make sure the derived fields are initially displayed right
    WorkPackages::UpdateAncestorsService
      .new(user:, work_package: child)
      .call(%i[estimated_hours remaining_hours done_ratio])

    login_as(user)
    wp_table.visit_query query
  end

  context "when changing a child work and remaining work values" do
    it "updates the derived parent work, remaining work, and % complete values" do
      expect do
        wp_table.update_work_package_attributes(child, estimatedTime: child.estimated_hours + 1)
        parent.reload
        child.reload
      end.to change(child, :remaining_hours).by(1) # remaining work increased as a side effect of increasing work
        .and change(parent, :derived_estimated_hours).by(1)
        .and change(parent, :derived_done_ratio).to(33) # 12h total work and 8h total remaining work => 33% complete
      expect do
        wp_table.update_work_package_attributes(child, remainingTime: child.remaining_hours + 2)
        parent.reload
      end.to change(parent, :derived_remaining_hours).by(2)
        .and change(parent, :derived_done_ratio).to(17) # 12h total work and 10h total remaining work => 17% complete
    end
  end

  context "when setting a child status to closed" do
    it "does not consider child % complete to be 100% and so does not update the derived parent % complete value" do
      expect do
        wp_table.update_work_package_attributes(child, status: "Closed")
        parent.reload
      end.not_to change(parent, :derived_done_ratio)
    end
  end

  context "when deleting a child" do
    it "updates the derived parent work, remaining work, and % complete values" do
      context_menu = wp_table.open_context_menu_for(second_child)
      context_menu.choose_delete_and_confirm_deletion

      parent.reload
      expect(parent.derived_estimated_hours).to eq([parent, child].pluck(:estimated_hours).sum)
      expect(parent.derived_remaining_hours).to eq([parent, child].pluck(:remaining_hours).sum)
      expect(parent.derived_done_ratio).to eq(child.done_ratio)
    end
  end

  def expect_totals(parent, descendants)
    parent.reload
    work_packages_for_total = [parent] + descendants
    expected_total_work = work_packages_for_total.pluck(:estimated_hours).sum
    expected_total_remaining_work = work_packages_for_total.pluck(:remaining_hours).sum
    expected_done_ratio = 100.0 * (1.0 - (expected_total_remaining_work / expected_total_work))
    expect(parent.derived_estimated_hours).to eq(expected_total_work)
    expect(parent.derived_remaining_hours).to eq(expected_total_remaining_work)
    expect(parent.derived_done_ratio).to eq(expected_done_ratio.round)
  end

  context "when adding a new child" do
    it "updates the derived parent work, remaining work, and % complete values" do
      context_menu = wp_table.open_context_menu_for(parent)
      context_menu.choose(I18n.t("js.relation_buttons.add_new_child"))

      split_view_create = Pages::SplitWorkPackageCreate.new(project:)
      split_view_create.set_attributes({ subject: "new child" })
      # Need a better way to deal with interacting with the
      # Progress Modal due to the intermediate updates it is
      # capable of.
      split_view_create.set_progress_attributes({ estimatedTime: 3, remainingTime: 1 })
      split_view_create.save!
      split_view_create.expect_and_dismiss_toaster message: "Successful creation"

      new_child = WorkPackage.last
      expect_totals(parent, [child, second_child, new_child])
    end
  end

  context "when outdenting and indenting hierarchy of a child" do
    it "updates the parent work and remaining work values" do
      context_menu = wp_table.open_context_menu_for(second_child)
      context_menu.choose(I18n.t("js.relation_buttons.hierarchy_outdent"))
      wp_table.expect_and_dismiss_toaster message: "Successful update"

      expect_totals(parent, [child])

      context_menu = wp_table.open_context_menu_for(second_child)
      context_menu.choose(I18n.t("js.relation_buttons.hierarchy_indent"))
      wp_table.expect_and_dismiss_toaster message: "Successful update"

      expect_totals(parent, [child, second_child])
    end
  end
end
