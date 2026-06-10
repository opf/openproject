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

RSpec.describe Backlogs::BucketComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:project) { create(:project, types: [type_feature]) }
  let(:show_all_backlog) { false }
  let(:backlog_bucket) { create(:backlog_bucket, project:, name: "Ready for development") }

  subject(:rendered_component) do
    render_component
  end

  def render_component
    vc_test_controller.params[:all] = "1" if show_all_backlog

    render_inline described_class.new(
      backlog_bucket:,
      project:,
      current_user: user
    )
  end

  describe "rendering" do
    context "with work packages" do
      let!(:work_package) do
        create(:work_package,
               subject: "Bucket Work Package",
               project:,
               backlog_bucket:,
               type: type_feature,
               status: default_status,
               priority: default_priority,
               story_points: 3,
               position: 1)
      end

      it_behaves_like "rendering Box", row_count: 1, header: true, footer: false

      it "renders the bucket box id derived from the bucket" do
        expect(rendered_component).to have_css(".Box#backlog_bucket_#{backlog_bucket.id}")
      end

      it "passes an explicit bucket test selector to the shared box" do
        expect(rendered_component).to have_css(".Box[data-test-selector='backlog-bucket-#{backlog_bucket.id}']")
      end

      it "renders the bucket title in the header" do
        expect(rendered_component).to have_heading "Ready for development", level: 4
        expect(rendered_component).to have_css("h4.f4", text: "Ready for development")
      end

      it "renders the generic work-package count in the header" do
        expect(rendered_component).to have_css(
          ".Counter",
          text: "1",
          aria: { label: I18n.t(:label_x_work_packages, count: 1), live: "polite" }
        )
      end

      it "does not render a story-points description in the header" do
        expect(rendered_component).to have_no_css(".velocity")
        expect(rendered_component).to have_no_css(".CollapsibleHeader-description")
      end

      it "renders the bucket kebab menu in the header" do
        expect(rendered_component).to have_button(accessible_name: "Backlog bucket actions")
      end

      it "renders the bucket menu actions" do
        expect(rendered_component.to_html).to include("Edit backlog bucket", "Delete backlog bucket")
      end

      it "renders one shared-card row per work package" do
        expect(rendered_component).to have_css(".Box-row", count: 1)
        expect(rendered_component).to have_text("Bucket Work Package")
        expect(rendered_component).to have_text("##{work_package.id}")
      end

      it "renders story points on the work package card" do
        expect(rendered_component).to have_css("span", text: "3", aria: { hidden: true })
        expect(rendered_component).to have_css(".sr-only", text: "3 story points")
      end

      it "wires the bucket drop-target data on the box" do
        expect(rendered_component).to have_css(".Box") do |box|
          expect(box["data-generic-drag-and-drop-target"]).to eq("container")
          expect(box["data-target-id"]).to eq("backlog_bucket:#{backlog_bucket.id}")
          expect(box["data-target-allowed-drag-type"]).to eq("story")
        end
      end

      it "renders the shared work-package row menu with inbox src" do
        expect(rendered_component).to have_element(
          "include-fragment",
          src: menu_project_backlogs_work_package_path(project, work_package)
        )
      end

      it "wires draggable row data through the shared card" do
        expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id}") do |row|
          expect(row["data-controller"]).to eq("backlogs--story")
          expect(row["data-draggable-id"]).to eq(work_package.id.to_s)
          expect(row["data-draggable-type"]).to eq("story")
          expect(row["data-drop-url"]).to end_with(move_project_backlogs_work_package_path(project, work_package))
          expect(row["data-backlogs--story-split-url-value"])
            .to end_with(project_backlogs_backlog_details_path(project, work_package))
          expect(row["data-backlogs--story-full-url-value"])
            .to end_with(work_package_path(work_package))
        end
      end
    end

    context "without work packages" do
      it_behaves_like "rendering Box", row_count: 1, header: true, footer: false
      it_behaves_like "rendering Blank Slate", heading: "Backlog bucket is empty"

      it "renders the bucket empty-state blankslate" do
        expect(rendered_component).to have_text("Backlog bucket is empty")
        expect(rendered_component).to have_text("Drag items here to add them.")
      end
    end
  end

  context "when show_all_backlog is active" do
    let(:show_all_backlog) { true }
    let!(:work_package) do
      create(:work_package,
             project:,
             backlog_bucket:,
             type: type_feature,
             status: default_status,
             priority: default_priority,
             position: 1)
    end

    it "includes all=1 in the split-view URL" do
      expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id}") do |row|
        expect(row["data-backlogs--story-split-url-value"]).to include("all=1")
      end
    end

    it "includes all=1 in the drop URL" do
      expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id}") do |row|
        expect(row["data-drop-url"]).to include("all=1")
      end
    end

    it "includes all=1 in the action-menu src" do
      expect(rendered_component).to have_element(
        "include-fragment",
        src: menu_project_backlogs_work_package_path(project, work_package, all: "1")
      )
    end
  end

  context "when the user lacks the create_sprints permission" do
    let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages manage_sprint_items]) }
    let(:user) { create(:user, member_with_roles: { project => role }) }
    let!(:work_package) do
      create(:work_package,
             project:,
             backlog_bucket:,
             type: type_feature,
             status: default_status,
             priority: default_priority,
             position: 1)
    end

    it "does not render the bucket header menu" do
      expect(rendered_component).to have_no_button(accessible_name: "Backlog bucket actions")
    end
  end

  context "when the bucket is not persisted" do
    let(:backlog_bucket) { BacklogBucket.new(project:, name: "Ready for development") }

    it "does not render the bucket header menu" do
      expect(rendered_component).to have_no_button(accessible_name: "Backlog bucket actions")
    end
  end

  context "when the user lacks the manage_sprint_items permission" do
    let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages create_sprints]) }
    let(:user) { create(:user, member_with_roles: { project => role }) }
    let!(:work_package) do
      create(:work_package,
             project:,
             backlog_bucket:,
             type: type_feature,
             status: default_status,
             priority: default_priority,
             position: 1)
    end

    it "does not mark work package rows as draggable" do
      expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id}")
      expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package.id}.Box-row--draggable")
      expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package.id}[data-draggable-id]")
      expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package.id}[data-drop-url]")
    end
  end
end
