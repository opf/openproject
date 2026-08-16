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

RSpec.describe Backlogs::WorkPackageCardMenuComponent, type: :component do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:readonly_status) { create(:status, :readonly) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project, types: [type_feature, type_task]) }
  let(:sprint) { create(:sprint, project:, name: "Sprint 1", start_date: Date.yesterday, finish_date: Date.tomorrow) }
  let(:bucket) { nil }
  let!(:first_story) { create_story(position: 1) }
  let!(:second_story) { create_story(position: 2) }
  let!(:third_story) { create_story(position: 3) }
  let!(:fourth_story) { create_story(position: 4) }
  let(:work_package) { second_story }
  let(:readonly_story) do
    create(:work_package,
           subject: "Rejected Story",
           project:,
           type: type_feature,
           status: readonly_status,
           priority: default_priority,
           position: 5,
           sprint:,
           backlog_bucket: bucket)
  end

  def create_story(position:, subject: "Test Story", story_points: 5)
    create(:work_package,
           subject:,
           project:,
           type: type_feature,
           status: default_status,
           priority: default_priority,
           story_points:,
           position:,
           sprint:,
           backlog_bucket: bucket)
  end

  def render_component(work_package: self.work_package,
                       sprint_ids: [sprint].compact.map(&:id),
                       bucket_ids: [bucket].compact.map(&:id))
    render_inline(described_class.new(
                    work_package:,
                    project:,
                    sprint_ids:,
                    bucket_ids:,
                    current_user: user
                  ))
  end

  describe "standard items" do
    it "renders stable ids for the list and primary actions" do
      render_component

      expect(page).to have_element(:ul, id: /\Awork_package_#{work_package.id}_menu-list\z/)
      expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_open_details\z/)
      expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_open_fullscreen\z/)
      expect(page).to have_element(:"clipboard-copy", id: /\Awork_package_#{work_package.id}_menu_copy_url_to_clipboard\z/)
      expect(page).to have_element(:"clipboard-copy", id: /\Awork_package_#{work_package.id}_menu_copy_work_package_id\z/)
    end

    it "shows Open details action (split view)" do
      render_component

      expect(page).to have_text(I18n.t(:"js.button_open_details"))
      expect(page).to have_octicon(:"op-view-split")
      expect(page).to have_css(
        "a[href$='/backlogs/backlog/details/#{work_package.id}'][data-action='backlogs--work-package#openSplitPane:prevent']",
        text: I18n.t(:"js.button_open_details")
      )
    end

    it "shows Open fullscreen link (full page)" do
      render_component

      expect(page).to have_text(I18n.t(:"js.button_open_fullscreen"))
      expect(page).to have_octicon(:"screen-full")
      expect(page).to have_css(
        "a[data-turbo-frame='_top']",
        text: I18n.t(:"js.button_open_fullscreen")
      )
    end

    it "shows Copy URL to clipboard action" do
      render_component

      expect(page).to have_octicon(:copy)
      expect(page).to have_element(
        :"clipboard-copy",
        id: "work_package_#{work_package.id}_menu_copy_url_to_clipboard",
        value: /\/work_packages\/#{work_package.id}\z/,
        text: "Copy URL to clipboard"
      )
    end

    it "shows Copy work package ID action" do
      render_component

      expect(page).to have_octicon(:hash)
      expect(page).to have_element(
        :"clipboard-copy",
        id: "work_package_#{work_package.id}_menu_copy_work_package_id",
        value: work_package.id.to_s,
        text: "Copy work package ID"
      )
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, types: [type_feature, type_task], identifier: "STORY") }

      it "uses the semantic displayId in the fullscreen and clipboard URLs" do
        render_component

        semantic_id = work_package.reload.identifier
        expect(semantic_id).to start_with("STORY-")

        fullscreen = page.find_by_id("work_package_#{work_package.id}_menu_open_fullscreen")
        expect(fullscreen[:href]).to end_with("/work_packages/#{semantic_id}")
        expect(fullscreen[:href]).not_to include("/work_packages/#{work_package.id}")

        clipboard = page.find("clipboard-copy##{"work_package_#{work_package.id}_menu_copy_url_to_clipboard"}")
        expect(clipboard[:value]).to end_with("/work_packages/#{semantic_id}")
        expect(clipboard[:value]).not_to include("/work_packages/#{work_package.id}")
      end

      it "copies the semantic identifier for the 'Copy work package ID' action" do
        render_component

        clipboard_id = page.find("clipboard-copy##{"work_package_#{work_package.id}_menu_copy_work_package_id"}")
        semantic_id = work_package.reload.identifier
        expect(clipboard_id[:value]).to eq(semantic_id)
      end
    end

    it "shows a divider before the Move submenu" do
      render_component

      expect(page).to have_css(".ActionList-sectionDivider")
    end

    it "wires the divider up to the item controller, so it can be hidden with the group" do
      render_component

      expect(page).to have_css(".ActionList-sectionDivider[data-sortable-lists--item-target='moveDivider']")
    end

    it "shows the Move to position submenu with incoming-arrow icon" do
      render_component

      expect(page).to have_selector(:menuitem, text: "Move to position")
      expect(page).to have_octicon(:"op-arrow-in")
    end
  end

  describe "move menu items" do
    it "renders project-level destination metadata including the invoking card's current target" do
      other_sprint = create(:sprint, project:, name: "Sprint 2", start_date: Date.yesterday, finish_date: Date.tomorrow)
      bucket = create(:backlog_bucket, project:)

      render_component(sprint_ids: [sprint.id, other_sprint.id], bucket_ids: [bucket.id])

      expect(page).to have_css(
        "li[data-sortable-lists--item-target~='destinationItem']" \
        "[data-sortable-lists-destinations*='\"type\":\"sprint\"']"
      )
      expect(page).to have_css("li[data-sortable-lists-destinations*='\"id\":\"#{sprint.id}\"']")
      expect(page).to have_css(
        "li[data-sortable-lists-destinations*='\"type\":\"#{Backlogs::Target::InboxId.list_type}\"']"
      )
    end

    it "shows Move to top item with move-to-top icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_highest))
      expect(page).to have_octicon(:"move-to-top")
    end

    it "shows Move up item with chevron-up icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_higher))
      expect(page).to have_octicon(:"chevron-up")
    end

    it "shows Move down item with chevron-down icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_lower))
      expect(page).to have_octicon(:"chevron-down")
    end

    it "shows Move to bottom item with move-to-bottom icon" do
      render_component

      expect(page).to have_text(I18n.t(:label_sort_lowest))
      expect(page).to have_octicon(:"move-to-bottom")
    end

    it "always renders the four move items as client targets", :aggregate_failures do
      render_inline(described_class.new(work_package:, project:, sprint_ids: [], bucket_ids: []))

      # The target, direction, and action live on the item <li>, not the content button.
      %w[top up down bottom].each do |direction|
        expect(page).to have_css(
          "li[data-sortable-lists--item-target='moveItem']" \
          "[data-sortable-lists--item-direction-param='#{direction}']" \
          "[data-action='click->sortable-lists--item#move']"
        )
      end
      expect(page).to have_css("li[data-sortable-lists--item-target='moveMenu']")
      expect(page).to have_no_field("direction", type: :hidden)
      expect(page).to have_no_field("prev_id", type: :hidden)
    end

    context "when the work package is the only item in its list" do
      let(:work_package) do
        solo_sprint = create(:sprint, project:, name: "Solo Sprint")
        create(:work_package,
               subject: "Solo Story",
               project:,
               type: type_feature,
               status: default_status,
               priority: default_priority,
               sprint: solo_sprint)
      end

      it "still shows all four move items; the client hides what does not apply" do
        render_component

        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
      end

      context "when the work package is already in the inbox" do
        let(:work_package) do
          create(:work_package,
                 subject: "Inbox Story",
                 project:,
                 type: type_feature,
                 status: default_status,
                 priority: default_priority)
        end

        it "still shows the Move to position submenu (permission-gated only)" do
          render_component(sprint_ids: [], bucket_ids: [])

          expect(page).to have_selector(:menuitem, text: "Move to position")
        end
      end
    end
  end

  describe "Move to sprint item" do
    context "when work package is in a sprint" do
      it "is shown with zap icon" do
        render_component(sprint_ids: [sprint.id])

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
        expect(page).to have_octicon(:zap)
        expect(page).to have_text(I18n.t(:"backlogs.work_package_card_menu_component.action_menu.move_to_sprint"))
      end
    end

    context "when work package is in a bucket" do
      let(:sprint) { nil }
      let(:bucket) { create(:backlog_bucket, project:) }

      it "is shown" do
        render_component(sprint_ids: [create(:sprint, project:).id])

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
      end
    end

    context "when work package is in the inbox" do
      let(:sprint) { nil }

      it "is shown" do
        render_component(sprint_ids: [create(:sprint, project:).id])

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
      end
    end

    it "is hidden when no sprint candidates exist" do
      render_component(sprint_ids: [])

      expect(page).to have_no_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
    end
  end

  describe "Move to backlog inbox item" do
    context "when work package is in a sprint" do
      it "is shown with inbox icon" do
        render_component

        expect(page).to have_element(:button, id: /\Awork_package_#{work_package.id}_menu_move_to_inbox\z/)
        expect(page).to have_octicon(:inbox)
        expect(page).to have_text(I18n.t(:"backlogs.work_package_card_menu_component.action_menu.move_to_inbox"))
        expect(page).to have_field("list_type", type: :hidden, with: Backlogs::Target::InboxId.list_type)
      end
    end

    context "when work package is in a bucket" do
      let(:sprint) { nil }
      let(:bucket) { create(:backlog_bucket, project:) }

      it "is shown" do
        render_component

        expect(page).to have_element(:button, id: /\Awork_package_#{work_package.id}_menu_move_to_inbox\z/)
      end
    end

    context "when work package is already in the inbox (no sprint, no bucket)" do
      let(:sprint) { nil }

      it "renders the inbox candidate for client-side projection" do
        render_component

        expect(page).to have_element(:button, id: /\Awork_package_#{work_package.id}_menu_move_to_inbox\z/)
      end
    end
  end

  describe "Move to backlog bucket item" do
    context "when work package is in a sprint" do
      it "is shown with package icon" do
        render_component(bucket_ids: [create(:backlog_bucket, project:).id])

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
        expect(page).to have_octicon(:package)
        expect(page).to have_text(I18n.t(:"backlogs.work_package_card_menu_component.action_menu.move_to_backlog_bucket"))
      end
    end

    context "when work package is in a bucket" do
      let(:sprint) { nil }
      let(:bucket) { create(:backlog_bucket, project:) }

      it "is shown" do
        render_component(bucket_ids: [bucket.id])

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
      end
    end

    context "when work package is in the inbox" do
      let(:sprint) { nil }

      it "is shown" do
        render_component(bucket_ids: [create(:backlog_bucket, project:).id])

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
      end
    end

    it "is hidden when no bucket candidates exist" do
      render_component(bucket_ids: [])

      expect(page).to have_no_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
    end
  end

  # A read-only status blocks every attribute write, so the server refuses the
  # sprint_id/backlog_bucket_id change a cross-container move performs — the
  # menu must not offer those. A reorder within the card's own list writes no
  # attribute and stays allowed, so the positional moves survive.
  describe "a work package in a read-only status" do
    let(:work_package) { readonly_story }

    context "with an Enterprise token", with_ee: %i[readonly_work_packages] do
      it "renders destination candidates for client-side confined-scope projection", :aggregate_failures do
        render_component

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
        expect(page).to have_element(:button, id: /\Awork_package_#{work_package.id}_menu_move_to_inbox\z/)
      end

      it "keeps the positional moves within its own list", :aggregate_failures do
        render_component

        expect(page).to have_selector(:menuitem, text: "Move to position")
        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
      end

      it "keeps the divider that separates the move group" do
        render_component

        expect(page).to have_css(".ActionList-sectionDivider")
      end

      it "still offers the actions that do not write to it", :aggregate_failures do
        render_component

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_open_details\z/)
        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_open_fullscreen\z/)
        expect(page).to have_element(:"clipboard-copy",
                                     id: /\Awork_package_#{work_package.id}_menu_copy_url_to_clipboard\z/)
        expect(page).to have_element(:"clipboard-copy",
                                     id: /\Awork_package_#{work_package.id}_menu_copy_work_package_id\z/)
      end
    end

    # Status#is_readonly always returns false without the token, so the same
    # work package is movable in Community and the bug cannot occur there.
    context "without an Enterprise token" do
      it "still offers the move actions" do
        render_component

        expect(page).to have_selector(:menuitem, text: "Move to position")
        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
      end
    end
  end
end
