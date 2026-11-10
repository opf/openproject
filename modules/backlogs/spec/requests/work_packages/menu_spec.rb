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

RSpec.describe "Backlogs card menu", type: :rails_request do
  shared_let(:type) { create(:type) }
  shared_let(:project) do
    create(:project, types: [type], enabled_module_names: %i[backlogs work_package_tracking])
  end
  shared_let(:sprint_a) { create(:sprint, project:, name: "Sprint A") }
  shared_let(:sprint_b) { create(:sprint, project:, name: "Sprint B") }

  let(:permissions) { %i[view_work_packages edit_work_packages view_sprints manage_sprint_items] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  def get_menu(ids:, invoker_id: ids.first)
    get menu_project_backlogs_work_packages_path(project, ids:, invoker_id:)
  end

  def menu
    Capybara.string(response.body)
  end

  def menu_item_id(work_package, item)
    "work_package_#{work_package.id}_menu_#{item}"
  end

  def singular_actions_for(work_package)
    have_element(:a, id: menu_item_id(work_package, :open_details))
      .and(have_element(:a, id: menu_item_id(work_package, :open_fullscreen)))
      .and(have_element(:"clipboard-copy", id: menu_item_id(work_package, :copy_url_to_clipboard)))
      .and(have_element(:"clipboard-copy", id: menu_item_id(work_package, :copy_work_package_id)))
  end

  def no_singular_actions_for(work_package)
    have_no_element(:a, id: menu_item_id(work_package, :open_details))
      .and(have_no_element(:a, id: menu_item_id(work_package, :open_fullscreen)))
      .and(have_no_element(:"clipboard-copy", id: menu_item_id(work_package, :copy_url_to_clipboard)))
      .and(have_no_element(:"clipboard-copy", id: menu_item_id(work_package, :copy_work_package_id)))
  end

  def move_to_position_for(work_package)
    have_selector(:menuitem, text: "Move to position")
      .and(have_element(:button, id: menu_item_id(work_package, :top)))
      .and(have_element(:button, id: menu_item_id(work_package, :up)))
      .and(have_element(:button, id: menu_item_id(work_package, :down)))
      .and(have_element(:button, id: menu_item_id(work_package, :bottom)))
  end

  context "with the invoker alone" do
    let!(:invoker) { create(:work_package, sprint: sprint_a, type:, project:) }

    it "keeps today's singular menu for one card", :aggregate_failures do
      get_menu(ids: [invoker.id])

      expect(response).to have_http_status(:ok)
      expect(menu).to have_element(:ul, id: "work_package_#{invoker.id}_menu-list")
      expect(menu).to singular_actions_for(invoker)
      expect(menu).to have_css(".ActionList-sectionDivider")
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_sprint))
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
      expect(menu).to move_to_position_for(invoker)
    end
  end

  context "with a multi-card scope in one sprint" do
    let!(:invoker) { create(:work_package, sprint: sprint_a, type:, project:) }
    let!(:other) { create(:work_package, sprint: sprint_a, type:, project:) }

    it "renders only batch actions for a multi-card scope", :aggregate_failures do
      get_menu(ids: [invoker.id, other.id])

      expect(response).to have_http_status(:ok)
      expect(menu).to have_element(:ul, id: "work_package_#{invoker.id}_menu-list")
      expect(menu).to no_singular_actions_for(invoker)
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_sprint))
      expect(menu).to move_to_position_for(invoker)
      expect(menu).to have_no_css(".ActionList-sectionDivider, .ActionList-sectionHeading")
      expect(menu).to have_no_text(/\b2\b/)
      expect(menu).to have_no_css("[aria-disabled]")
      expect(menu).to have_no_css("[data-sortable-lists--item-target='moveUnavailable']", visible: :all)
    end
  end

  describe "a multi-card scope of confined members", with_ee: %i[readonly_work_packages] do
    shared_let(:readonly_status) { create(:status, :readonly) }

    let(:explanation) { "No actions available for the selected work packages." }

    context "when they share one list" do
      let!(:invoker) { create(:work_package, sprint: sprint_a, status: readonly_status, type:, project:) }
      let!(:other) { create(:work_package, sprint: sprint_a, status: readonly_status, type:, project:) }

      it "keeps the batch menu when only Move to position applies", :aggregate_failures do
        get_menu(ids: [invoker.id, other.id])

        expect(response).to have_http_status(:ok)
        expect(menu).to no_singular_actions_for(invoker)
        expect(menu).to have_no_element(:button, id: /_menu_move_to_(inbox|sprint|backlog_bucket)\z/)
        expect(menu).to move_to_position_for(invoker)
      end

      it "sends the explanation hidden when Move to position is the only batch action", :aggregate_failures do
        get_menu(ids: [invoker.id, other.id])

        expect(menu).to have_css(
          "li[hidden][data-sortable-lists--item-target='moveUnavailable'] ##{menu_item_id(invoker, :no_batch_actions)}",
          visible: :hidden
        )
      end
    end

    context "when they span lists" do
      let!(:invoker) { create(:work_package, sprint: sprint_a, status: readonly_status, type:, project:) }
      let!(:other) { create(:work_package, sprint: sprint_b, status: readonly_status, type:, project:) }

      it "explains a batch that no action applies to", :aggregate_failures do
        get_menu(ids: [invoker.id, other.id])

        expect(response).to have_http_status(:ok)
        expect(menu).to have_element(:ul,
                                     id: "work_package_#{invoker.id}_menu-list",
                                     "data-sortable-lists-scope-count": "2")
        expect(menu).to have_selector(:menuitem, text: explanation, disabled: true, count: 1)
        expect(menu).to no_singular_actions_for(invoker)
        expect(menu).to have_no_css("[data-sortable-lists--item-target]", visible: :all)
        expect(menu).to have_no_element(:button, id: menu_item_id(invoker, :top))
        expect(menu).to have_no_css(".ActionList-sectionDivider")
      end
    end
  end

  describe "offers a sprint only when every member permits it", with_ee: %i[readonly_work_packages] do
    shared_let(:readonly_status) { create(:status, :readonly) }

    let!(:confined) { create(:work_package, sprint: sprint_a, status: readonly_status, type:, project:) }

    context "when a confined member sits in one sprint and a free member elsewhere" do
      let!(:free) { create(:work_package, type:, project:) }

      it "offers the sprint every member can reach" do
        get_menu(ids: [free.id, confined.id])

        expect(menu).to have_element(:button, id: menu_item_id(free, :move_to_sprint))
      end
    end

    context "when the only other sprint is refused by a confined member" do
      let!(:free) { create(:work_package, sprint: sprint_a, type:, project:) }

      it "offers no sprint", :aggregate_failures do
        get_menu(ids: [free.id, confined.id])

        expect(response).to have_http_status(:ok)
        expect(menu).to have_no_element(:button, id: menu_item_id(free, :move_to_sprint))
      end
    end
  end

  describe "Move to position" do
    context "when all ids share one list" do
      let!(:first) { create(:work_package, sprint: sprint_a, type:, project:) }
      let!(:second) { create(:work_package, sprint: sprint_a, type:, project:) }

      it "renders Move to position when all ids share one list" do
        get_menu(ids: [first.id, second.id])

        expect(menu).to move_to_position_for(first)
      end
    end

    context "when the ids span lists" do
      let!(:first) { create(:work_package, sprint: sprint_a, type:, project:) }
      let!(:second) { create(:work_package, sprint: sprint_b, type:, project:) }

      it "omits Move to position for a cross-list scope", :aggregate_failures do
        get_menu(ids: [first.id, second.id])

        expect(response).to have_http_status(:ok)
        %i[top up down bottom].each do |direction|
          expect(menu).to have_no_element(:button, id: menu_item_id(first, direction))
        end
      end
    end

    context "with a confined member", with_ee: %i[readonly_work_packages] do
      shared_let(:readonly_status) { create(:status, :readonly) }

      let!(:free) { create(:work_package, sprint: sprint_a, type:, project:) }
      let!(:confined) { create(:work_package, sprint: sprint_a, status: readonly_status, type:, project:) }

      it "renders it for confined members" do
        get_menu(ids: [free.id, confined.id])

        expect(menu).to move_to_position_for(free)
      end
    end
  end

  context "when every member is already in the inbox" do
    let!(:first) { create(:work_package, type:, project:) }
    let!(:second) { create(:work_package, type:, project:) }

    it "omits a target every member is already in" do
      get_menu(ids: [first.id, second.id])

      expect(menu).to have_no_element(:button, id: menu_item_id(first, :move_to_inbox))
    end
  end

  context "when one member is in the inbox and another is not" do
    let!(:invoker) { create(:work_package, type:, project:) }
    let!(:sprinted) { create(:work_package, sprint: sprint_a, type:, project:) }

    it "offers the inbox" do
      get_menu(ids: [invoker.id, sprinted.id])

      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
    end
  end

  describe "a stale selection" do
    let!(:invoker) { create(:work_package, sprint: sprint_a, type:, project:) }
    let!(:unavailable) { create(:work_package, type:, project:) }
    let!(:last) { create(:work_package, sprint: sprint_a, type:, project:) }

    %i[missing inaccessible].each do |state|
      it "omits all mutations when the middle member is #{state}", :aggregate_failures do
        if state == :missing
          unavailable.destroy!
        else
          unavailable.update_columns(project_id: create(:project).id)
        end

        get_menu(ids: [invoker.id, unavailable.id, last.id])

        expect(response).to have_http_status(:ok)
        expect(menu).to singular_actions_for(invoker)
        expect(menu).to have_css("[role='menuitem']", count: 5)
        expect(menu).to have_selector(:menuitem,
                                      text: "The selection has changed. Refresh it before moving work packages.",
                                      disabled: true,
                                      count: 1)
        expect(menu).to have_css("[data-sortable-lists-scope-count='1']")
        expect(menu).to have_no_css("form, [data-sortable-lists--item-target]", visible: :all)
        expect(menu).to have_no_element(:button, id: /_menu_move_to_/)
      end
    end

    it "keeps a visible member that changed lists in the requested scope" do
      unavailable.update_columns(sprint_id: sprint_b.id)

      get_menu(ids: [invoker.id, unavailable.id, last.id])

      expect(response).to have_http_status(:ok)
      expect(menu).to have_css("[data-sortable-lists-scope-count='3']")
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
    end
  end

  context "when the invoker is gone" do
    let!(:member) { create(:work_package, type:, project:) }
    let!(:invoker) { create(:work_package, type:, project:) }

    before { invoker.destroy }

    it "responds with not found" do
      get_menu(ids: [member.id, invoker.id], invoker_id: invoker.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "with more ids than the batch cap" do
    shared_let(:bucket) { create(:backlog_bucket, project:) }

    let!(:work_packages) do
      create_list(:work_package, Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE + 1, type:, project:)
    end
    let(:invoker) { work_packages.first }
    let(:explanation) { "Cannot move 51 work packages at once. Select no more than 50." }

    it "keeps movement enabled at the exact batch cap" do
      get_menu(ids: work_packages.first(50).map(&:id))

      expect(menu).to have_css("[data-sortable-lists-scope-count='50']")
      expect(menu).to have_selector(:menuitem, text: "Move to position")
      expect(menu).to have_no_css("[aria-disabled='true']")
    end

    it "treats a missing member as stale before checking the cap", :aggregate_failures do
      ids = work_packages.map(&:id)
      work_packages[1].destroy!

      get_menu(ids:)

      expect(menu).to singular_actions_for(invoker)
      expect(menu).to have_css("[data-sortable-lists-scope-count='1']")
      expect(menu).to have_selector(:menuitem,
                                    text: "The selection has changed. Refresh it before moving work packages.",
                                    disabled: true)
      expect(menu).to have_no_text(explanation)
      expect(menu).to have_no_css("form, [data-sortable-lists--item-target]", visible: :all)
    end

    it "keeps the cap explanation when no destination accepts the cross-list batch",
       :aggregate_failures, with_ee: %i[readonly_work_packages] do
      destination = sprint_a
      readonly_status = create(:status, :readonly)
      WorkPackage.where(id: work_packages.map(&:id)).update_all(status_id: readonly_status.id)
      work_packages.last.reload.update_columns(sprint_id: destination.id)
      expect(WorkPackage.where(id: work_packages.map(&:id)).distinct.pluck(:sprint_id)).to contain_exactly(nil, destination.id)

      get_menu(ids: work_packages.map(&:id))

      expect(menu).to have_css("[data-sortable-lists-scope-count='51']")
      expect(menu).to have_selector(:menuitem, text: explanation, disabled: true, count: 1)
      expect(menu).to no_singular_actions_for(invoker)
      expect(menu).to have_no_text("Move to position")
      expect(menu).to have_no_css("form", visible: :all)
      expect(menu).to have_no_element(:button, id: /_menu_move_to_/)
    end

    it "disables batch move actions above the batch cap and explains why", :aggregate_failures do
      get_menu(ids: work_packages.map(&:id))

      expect(response).to have_http_status(:ok)
      expect(menu).to no_singular_actions_for(invoker)

      %i[move_to_sprint move_to_backlog_bucket].each do |item|
        expect(menu).to have_element(:button, id: menu_item_id(invoker, item), "aria-disabled": "true")
      end
      expect(menu).to have_selector(:menuitem, text: "Move to position", disabled: true)
      %i[top up down bottom].each do |direction|
        expect(menu).to have_element(:button, id: menu_item_id(invoker, direction), "aria-disabled": "true")
      end
      expect(menu).to have_no_css(".ActionListContent:not([aria-disabled='true'])")

      expect(menu).to have_text(explanation, count: 1)
      expect(menu).to have_selector(:menuitem, text: explanation, disabled: true)
    end
  end

  context "without the view_sprints permission" do
    let(:permissions) { %i[view_work_packages] }
    let!(:invoker) { create(:work_package, type:, project:) }

    it "refuses without view permission" do
      get_menu(ids: [invoker.id])

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "parameter validation" do
    let!(:invoker) { create(:work_package, type:, project:) }
    let!(:other) { create(:work_package, type:, project:) }

    it "rejects an invoker outside ids" do
      get_menu(ids: [other.id], invoker_id: invoker.id)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate ids" do
      get_menu(ids: [invoker.id, invoker.id])

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a blank id" do
      get_menu(ids: [invoker.id, ""])

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
