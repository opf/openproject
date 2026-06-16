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
  let(:displayed_work_packages) { WorkPackage.where(sprint:).order_by_position }
  let(:work_package) { enrich_with_neighbours(second_story) }

  def enrich_with_neighbours(work_package, scope: displayed_work_packages)
    scope.with_backlogs_neighbours.find(work_package.id)
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

  def render_component(work_package: self.work_package, open_sprints_exist: true, other_buckets_exist: true)
    render_inline(described_class.new(
                    work_package:,
                    project:,
                    open_sprints_exist:,
                    other_buckets_exist:,
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

    it "shows Open details link (split view)" do
      render_component

      expect(page).to have_text(I18n.t(:"js.button_open_details"))
      expect(page).to have_octicon(:"op-view-split")
      expect(page).to have_css(
        "a[data-turbo-frame='content-bodyRight'][data-turbo-action='advance']",
        text: I18n.t(:"js.button_open_details")
      )
    end

    context "when params[:all] is true" do
      before { vc_test_controller.params[:all] = "1" }

      it "adds the all param to the open details href" do
        render_component

        expect(page).to have_css(%(#work_package_#{work_package.id}_menu_open_details[href*="all=1"]))
      end
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

      it "uses the semantic displayId in the open details, fullscreen, and clipboard URLs" do
        render_component

        semantic_id = work_package.reload.identifier
        expect(semantic_id).to start_with("STORY-")

        details = page.find_by_id("work_package_#{work_package.id}_menu_open_details")
        expect(details[:href]).to include("/details/#{semantic_id}")
        expect(details[:href]).not_to include("/details/#{work_package.id}")

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

    it "shows the Move to position submenu with incoming-arrow icon" do
      render_component

      expect(page).to have_selector(:menuitem, text: "Move to position")
      expect(page).to have_octicon(:"op-arrow-in")
    end
  end

  describe "move menu items" do
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

    context "when item is first" do
      let(:work_package) { enrich_with_neighbours(first_story) }

      it "hides Move to top and Move up" do
        render_component

        expect(page).to have_no_text(I18n.t(:label_sort_highest))
        expect(page).to have_no_text(I18n.t(:label_sort_higher))
      end

      it "shows Move down and Move to bottom, sending next_id as prev_id" do
        render_component

        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
        expect(page).to have_field("prev_id", type: :hidden, count: 1)
        expect(page).to have_field("prev_id", type: :hidden, with: second_story.id.to_s)
      end
    end

    context "when item is in the middle with one predecessor" do
      it "shows all move options, sending nil prev_id for Move up and next_id as prev_id for Move down" do
        render_component

        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
        expect(page).to have_field("prev_id", type: :hidden, count: 2)
        expect(page).to have_field("prev_id", type: :hidden, with: third_story.id.to_s)
      end
    end

    context "when item is in the middle with two predecessors" do
      let(:work_package) { enrich_with_neighbours(third_story) }

      it "shows all move options, sending prev_prev_id and next_id as prev_id" do
        render_component

        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
        expect(page).to have_text(I18n.t(:label_sort_lower))
        expect(page).to have_text(I18n.t(:label_sort_lowest))
        expect(page).to have_field("prev_id", type: :hidden, with: first_story.id.to_s)
        expect(page).to have_field("prev_id", type: :hidden, with: fourth_story.id.to_s)
      end
    end

    context "when item is last" do
      let(:work_package) { enrich_with_neighbours(fourth_story) }

      it "hides Move down and Move to bottom" do
        render_component

        expect(page).to have_no_text(I18n.t(:label_sort_lower))
        expect(page).to have_no_text(I18n.t(:label_sort_lowest))
      end

      it "shows Move to top and Move up, sending prev_prev_id as prev_id" do
        render_component

        expect(page).to have_text(I18n.t(:label_sort_highest))
        expect(page).to have_text(I18n.t(:label_sort_higher))
        expect(page).to have_field("prev_id", type: :hidden, count: 1)
        expect(page).to have_field("prev_id", type: :hidden, with: second_story.id.to_s)
      end
    end

    context "when there is only one item" do
      let(:displayed_work_packages) { WorkPackage.where(id: second_story.id).order_by_position }

      it "hides all move options" do
        render_component

        expect(page).to have_no_text(I18n.t(:label_sort_highest))
        expect(page).to have_no_text(I18n.t(:label_sort_higher))
        expect(page).to have_no_text(I18n.t(:label_sort_lower))
        expect(page).to have_no_text(I18n.t(:label_sort_lowest))
      end

      context "when the work package is already in the inbox" do
        let(:sprint) { nil }

        it "hides the Move to position submenu entirely" do
          render_component(open_sprints_exist: false, other_buckets_exist: false)

          expect(page).to have_no_selector(:menuitem, text: "Move to position")
        end
      end
    end
  end

  describe "Move to sprint item" do
    context "when work package is in a sprint" do
      it "is shown with zap icon" do
        render_component(open_sprints_exist: true)

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
        expect(page).to have_octicon(:zap)
        expect(page).to have_text(I18n.t(:"backlogs.work_package_card_menu_component.action_menu.move_to_sprint"))
      end
    end

    context "when work package is in a bucket" do
      let(:sprint) { nil }
      let(:bucket) { create(:backlog_bucket, project:) }

      it "is shown" do
        render_component(open_sprints_exist: true)

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
      end
    end

    context "when work package is in the inbox" do
      let(:sprint) { nil }

      it "is shown" do
        render_component(open_sprints_exist: true)

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
      end
    end

    it "is hidden when open_sprints_exist is false" do
      render_component(open_sprints_exist: false)

      expect(page).to have_no_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_sprint\z/)
    end

    context "when params[:all] is true" do
      before { vc_test_controller.params[:all] = "1" }

      it "adds the all param to the move to sprint href" do
        render_component(open_sprints_exist: true)

        expect(page).to have_css(%(#work_package_#{work_package.id}_menu_move_to_sprint[href*="all=1"]))
      end
    end
  end

  describe "Move to backlog inbox item" do
    context "when work package is in a sprint" do
      it "is shown with inbox icon" do
        render_component

        expect(page).to have_element(:button, id: /\Awork_package_#{work_package.id}_menu_move_to_inbox\z/)
        expect(page).to have_octicon(:inbox)
        expect(page).to have_text(I18n.t(:"backlogs.work_package_card_menu_component.action_menu.move_to_inbox"))
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

      it "is hidden" do
        render_component

        expect(page).to have_no_element(:button, id: /\Awork_package_#{work_package.id}_menu_move_to_inbox\z/)
      end
    end

    context "when params[:all] is true" do
      before { vc_test_controller.params[:all] = "1" }

      it "adds the all param to the form action for the inbox move" do
        render_component

        expect(page).to have_css(%(form[action*="all=1"]))
      end
    end
  end

  describe "Move to backlog bucket item" do
    context "when work package is in a sprint" do
      it "is shown with package icon" do
        render_component(other_buckets_exist: true)

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
        expect(page).to have_octicon(:package)
        expect(page).to have_text(I18n.t(:"backlogs.work_package_card_menu_component.action_menu.move_to_backlog_bucket"))
      end
    end

    context "when work package is in a bucket" do
      let(:sprint) { nil }
      let(:bucket) { create(:backlog_bucket, project:) }

      it "is shown" do
        render_component(other_buckets_exist: true)

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
      end
    end

    context "when work package is in the inbox" do
      let(:sprint) { nil }

      it "is shown" do
        render_component(other_buckets_exist: true)

        expect(page).to have_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
      end
    end

    it "is hidden when other_buckets_exist is false" do
      render_component(other_buckets_exist: false)

      expect(page).to have_no_element(:a, id: /\Awork_package_#{work_package.id}_menu_move_to_backlog_bucket\z/)
    end

    context "when params[:all] is true" do
      before { vc_test_controller.params[:all] = "1" }

      it "adds the all param to the dialog href" do
        render_component(other_buckets_exist: true)

        expect(page).to have_css(%(#work_package_#{work_package.id}_menu_move_to_backlog_bucket[href*="all=1"]))
      end
    end
  end
end
