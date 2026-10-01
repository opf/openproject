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
  end

  describe "hidden filter fields" do
    it "passes through sprint_ids when rendering the bucket panel" do
      render_component(field_name: :bucket_ids, sprint_ids: ["1"])
      expect(page).to have_field("sprint_ids[]", type: :hidden, with: "1", visible: :all)
    end

    it "passes through bucket_ids when rendering the sprint panel" do
      render_component(field_name: :sprint_ids, bucket_ids: ["2"])
      expect(page).to have_field("bucket_ids[]", type: :hidden, with: "2", visible: :all)
    end

    it "expands array values into multiple hidden inputs" do
      render_component(field_name: :sprint_ids, bucket_ids: [1, 2])
      expect(page).to have_field("bucket_ids[]", type: :hidden, with: "1", visible: :all)
      expect(page).to have_field("bucket_ids[]", type: :hidden, with: "2", visible: :all)
    end

    it "passes through scalar params as a single hidden input without brackets" do
      render_component(field_name: :sprint_ids, all: true)
      # The clear form has 1 `all`, the filter form has 1 `all` and 1 `sprint_ids[]` parameter
      expect(page).to have_field(type: :hidden, count: 3, visible: :all)
      expect(page).to have_field("all", type: :hidden, with: "true", count: 2, visible: :all)
      expect(page).to have_field("sprint_ids[]", type: :hidden, count: 1, visible: :all)
    end
  end
end
