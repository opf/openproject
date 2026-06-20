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

RSpec.describe Backlogs::BacklogFilterSelectPanelComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }

  current_user { user }

  def render_component(field_name:, **params)
    params.each { |k, v| vc_test_controller.params[k] = v }
    render_inline(described_class.new(project:, field_name:))
  end

  describe "sprint panel" do
    shared_let(:sprint1) { create(:sprint, project:, name: "Alpha Sprint") }
    shared_let(:sprint2) { create(:sprint, project:, name: "Beta Sprint") }

    it "shows 'Sprints' as the button label" do
      render_component(field_name: :sprint_ids)
      expect(page).to have_button("All sprints")
    end

    it "renders all sprints as items" do
      render_component(field_name: :sprint_ids)
      expect(page).to have_text("Alpha Sprint")
      expect(page).to have_text("Beta Sprint")
    end

    it "marks selected sprints as active" do
      render_component(field_name: :sprint_ids, sprint_ids: [sprint1.id])
      expect(page).to have_css("[aria-selected='true']", text: "Alpha Sprint")
      expect(page).to have_css("[aria-selected='false']", text: "Beta Sprint")
    end

    it "scopes each item id under the panel id" do
      render_component(field_name: :sprint_ids)
      expect(page).to have_css("#sprint_filter_select_panel_item_#{sprint1.id}", visible: :all, text: "Alpha Sprint")
      expect(page).to have_css("#sprint_filter_select_panel_item_#{sprint2.id}", visible: :all, text: "Beta Sprint")
    end
  end

  describe "bucket panel" do
    shared_let(:bucket1) { create(:backlog_bucket, project:, name: "Ideas") }
    shared_let(:bucket2) { create(:backlog_bucket, project:, name: "Backlog") }

    it "shows 'Backlog buckets' as the button label" do
      render_component(field_name: :bucket_ids)
      expect(page).to have_button("All backlog buckets")
    end

    it "renders all buckets as items" do
      render_component(field_name: :bucket_ids)
      expect(page).to have_text("Ideas")
      expect(page).to have_text("Backlog")
    end

    it "marks selected buckets as active" do
      render_component(field_name: :bucket_ids, bucket_ids: [bucket2.id])
      expect(page).to have_element(aria: { selected: false }, text: "Ideas")
      expect(page).to have_element(aria: { selected: true }, text: "Backlog")
    end

    it "scopes each item id under the panel id, including the inbox sentinel" do
      render_component(field_name: :bucket_ids)
      expect(page).to have_css("#backlog_bucket_filter_select_panel_item_#{bucket1.id}", visible: :all, text: "Ideas")
      expect(page).to have_css("#backlog_bucket_filter_select_panel_item_#{bucket2.id}", visible: :all, text: "Backlog")
      expect(page).to have_css("#backlog_bucket_filter_select_panel_item_inbox", visible: :all, text: I18n.t(:label_inbox))
    end
  end

  describe "stable DOM ids" do
    it "derives the sprint panel and its trigger button ids from the field name" do
      render_component(field_name: :sprint_ids)

      expect(page).to have_css("#sprint_filter_select_panel", visible: :all)
      expect(page).to have_css("#sprint_filter_select_panel-button", visible: :all)
    end

    it "derives the bucket panel and its trigger button ids from the field name" do
      render_component(field_name: :bucket_ids)

      expect(page).to have_css("#backlog_bucket_filter_select_panel", visible: :all)
      expect(page).to have_css("#backlog_bucket_filter_select_panel-button", visible: :all)
    end
  end

  describe "submission wiring" do
    it "wires the panel root to refresh buttons on change and revert on close" do
      render_component(field_name: :bucket_ids)

      expect(page).to have_css(
        "[data-controller='backlogs--backlog-filter-select-panel']" \
        "[data-backlogs--backlog-filter-select-panel-filter-key-value='bucket_ids']" \
        "[data-action*='itemActivated->backlogs--backlog-filter-select-panel#refreshButtons']" \
        "[data-action*='panelClosed->backlogs--backlog-filter-select-panel#revertOnClose']"
      )
    end

    it "renders the Apply button disabled and wired to the apply action" do
      render_component(field_name: :sprint_ids)

      apply = page.find(
        "button[data-action='click->backlogs--backlog-filter-select-panel#apply']",
        visible: :all
      )
      expect(apply).to be_disabled
      expect(apply).to have_text(I18n.t(:button_apply))
      expect(apply["data-backlogs--backlog-filter-select-panel-target"]).to eq("applyButton")
    end

    it "disables the Clear button when no filter is selected" do
      render_component(field_name: :bucket_ids)

      clear = page.find(
        "button[data-action='click->backlogs--backlog-filter-select-panel#clear']",
        visible: :all
      )
      expect(clear).to be_disabled
      expect(clear["data-backlogs--backlog-filter-select-panel-target"]).to eq("clearButton")
    end

    it "enables the Clear button when a filter is already selected" do
      render_component(field_name: :bucket_ids, bucket_ids: ["1"])

      clear = page.find(
        "button[data-action='click->backlogs--backlog-filter-select-panel#clear']",
        visible: :all
      )
      expect(clear).not_to be_disabled
    end
  end
end
