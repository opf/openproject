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
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[backlogs]) }
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

    it "marks sprints selected in the JSON format as active" do
      render_component(field_name: :sprint_ids, sprint_ids: [sprint2.id.to_s].to_json)
      expect(page).to have_css("[aria-selected='false']", text: "Alpha Sprint")
      expect(page).to have_css("[aria-selected='true']", text: "Beta Sprint")
    end

    it "does not list completed sprints" do
      create(:sprint, project:, name: "Done Sprint", status: :completed)
      render_component(field_name: :sprint_ids)
      expect(page).to have_no_text("Done Sprint")
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

    it "marks inbox as active when selected in the JSON format" do
      render_component(field_name: :bucket_ids, bucket_ids: [bucket1.id.to_s, "inbox"].to_json)
      expect(page).to have_element(aria: { selected: true }, text: "Ideas")
      expect(page).to have_element(aria: { selected: false }, text: "Backlog")
      expect(page).to have_element(aria: { selected: true }, text: I18n.t(:label_inbox))
    end
  end

  describe "stimulus wiring" do
    it "configures the filter select panel controller with the filter key and base url" do
      render_component(field_name: :sprint_ids)

      expect(page).to have_element(
        "select-panel",
        "data-controller": "backlogs--filter-select-panel",
        "data-backlogs--filter-select-panel-filter-key-value": "sprint_ids",
        "data-backlogs--filter-select-panel-base-url-value": project_backlogs_backlog_path(project)
      )
    end

    it "disables the clear button when nothing is selected" do
      render_component(field_name: :bucket_ids)
      expect(page).to have_button(I18n.t(:button_clear), disabled: true)
    end

    it "enables the clear button when a filter is applied" do
      render_component(field_name: :bucket_ids, bucket_ids: "inbox".to_json)
      expect(page).to have_button(I18n.t(:button_clear), disabled: false)
    end
  end
end
