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

RSpec.describe Backlogs::BucketComponent, type: :component, with_flag: { backlogs_lazy_cards: true } do
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

      it "parks the empty-state prototype in a template for the dynamic controller" do
        expect(rendered_component)
          .to have_css("template[data-border-box-list-target='emptyStateTemplate']", visible: :all)
      end

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
        expect(rendered_component).to have_selector(:menuitem, "Edit backlog bucket") do |link|
          expect(link[:href]).to eq edit_dialog_project_backlogs_bucket_path(project, backlog_bucket)
        end
        expect(rendered_component).to have_selector(:menuitem, "Delete backlog bucket") do |link|
          expect(link[:href]).to eq destroy_dialog_project_backlogs_bucket_path(project, backlog_bucket)
        end
        expect(rendered_component).to have_selector(:menuitem, "Add new work package") do |link|
          expect(link[:href]).to eq new_project_work_packages_dialog_path(project, backlog_bucket_id: backlog_bucket.id)
        end
        expect(rendered_component).to have_selector(:menuitem, "Add existing work package") do |link|
          expect(link[:href]).to eq add_existing_dialog_project_backlogs_work_packages_path(
            project, list_type: "backlog_bucket", list_id: backlog_bucket.id
          )
        end
      end

      it "lazily loads the work package card through a turbo-frame" do
        expect(rendered_component).to have_css(
          ".Box-row#work_package_#{work_package.id} " \
          "turbo-frame#card_work_package_#{work_package.id}[loading='lazy']" \
          "[src*='#{project_backlogs_work_package_card_path(project, work_package)}']"
        )
      end

      context "when the backlogs_lazy_cards feature is disabled", with_flag: { backlogs_lazy_cards: false } do
        it "renders the card inline without a turbo-frame" do
          expect(rendered_component).to have_text("Bucket Work Package")
          expect(rendered_component).to have_text("##{work_package.id}")

          expect(rendered_component).to have_css(
            ".Box-row#work_package_#{work_package.id} .sr-only", text: "3 story points"
          )

          expect(rendered_component).to have_no_css("turbo-frame#card_work_package_#{work_package.id}")
        end
      end

      it "wires the list controller and value attributes for the bucket" do
        list_type = Backlogs::Target::BucketId.new(backlog_bucket.id).list_type

        expect(rendered_component).to have_css(".Box") do |box|
          expect(box["data-controller"]).to include("sortable-lists--list")
          expect(box["data-sortable-lists--list-type-value"]).to eq(list_type)
          expect(box["data-sortable-lists--list-id-value"]).to eq(backlog_bucket.id.to_s)
          expect(box["data-sortable-lists--list-accepted-type-value"]).to eq("work_package")
          expect(box["data-sortable-lists--list-drop-position-value"]).to eq("start")
        end
      end

      it "wires draggable data through the shared row when lazy loading is disabled", with_flag: { backlogs_lazy_cards: false } do
        expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id}") do |row|
          expect(row["data-controller"]).to eq("sortable-lists--item")
          expect(row["data-sortable-lists--item-id-value"]).to eq(work_package.id.to_s)
          expect(row["data-sortable-lists--item-type-value"]).to eq("work_package")
          expect(row["draggable"]).to eq("true")
        end

        expect(rendered_component).to have_css(".op-work-package-card") do |card|
          expect(card["data-controller"].split).to include("backlogs--work-package")
          expect(card["data-sortable-lists--item-target"]).to eq("preview handle")
          expect(card["data-backlogs--work-package-split-url-value"])
            .to end_with(project_backlogs_backlog_details_path(project, work_package))
          expect(card["data-backlogs--work-package-full-url-value"])
            .to end_with(work_package_path(work_package))
        end
      end
    end

    context "without work packages" do
      it_behaves_like "rendering Box", row_count: 0, header: true, footer: false
      it_behaves_like "rendering Blank Slate", heading: "Backlog bucket is empty"

      it "renders the bucket empty-state blankslate" do
        expect(rendered_component).to have_text("Backlog bucket is empty")
        expect(rendered_component).to have_text("Drag items here to add them")
      end
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

    it "still renders the add work package menu actions" do
      expect(rendered_component).to have_button(accessible_name: "Backlog bucket actions")
      expect(rendered_component).to have_selector(:menuitem, "Add new work package")
      expect(rendered_component).to have_selector(:menuitem, "Add existing work package")
    end

    it "does not render the edit or delete bucket menu items" do
      expect(rendered_component).to have_no_selector(:menuitem, "Edit backlog bucket")
      expect(rendered_component).to have_no_selector(:menuitem, "Delete backlog bucket")
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
      expect(rendered_component)
        .to have_no_css(".Box-row#work_package_#{work_package.id}[data-sortable-lists--item-id-value]")
      expect(rendered_component).to have_no_css(".Box-row#work_package_#{work_package.id}[draggable='true']")
      expect(rendered_component).to have_no_css(".op-work-package-card[data-sortable-lists--item-id-value]")
      expect(rendered_component).to have_no_css(".op-work-package-card[data-sortable-lists--item-target]")
      expect(rendered_component).to have_no_css(".op-work-package-card[draggable='true']")
      expect(rendered_component).to have_no_css(".op-work-package-card.Box-card--draggable")
    end

    it "still renders the edit and delete bucket menu items" do
      expect(rendered_component).to have_button(accessible_name: "Backlog bucket actions")
      expect(rendered_component).to have_selector(:menuitem, "Edit backlog bucket")
      expect(rendered_component).to have_selector(:menuitem, "Delete backlog bucket")
    end

    it "does not render the add work package menu actions" do
      expect(rendered_component).to have_no_selector(:menuitem, "Add new work package")
      expect(rendered_component).to have_no_selector(:menuitem, "Add existing work package")
    end
  end
end
