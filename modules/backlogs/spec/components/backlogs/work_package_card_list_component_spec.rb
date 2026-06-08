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

RSpec.describe Backlogs::WorkPackageCardListComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  shared_let(:project) { create(:project, types: [type_feature]) }
  shared_let(:sprint) do
    create(:sprint, project:, name: "Sprint 1",
                    start_date: Date.yesterday, finish_date: Date.tomorrow)
  end
  shared_let(:backlog_bucket) { create(:backlog_bucket, project:, name: "Bucket A") }

  let(:container) { sprint }
  let(:drag_and_drop) { nil }
  let(:params) { {} }
  let(:work_packages) { [] }
  let(:header_arguments) { nil }
  let(:footer_content) { nil }

  subject(:rendered_component) do
    render_component(work_packages:, container:, drag_and_drop:)
  end

  def render_component(work_packages:, container:, drag_and_drop:)
    render_inline(
      described_class.new(
        work_packages:,
        project:,
        container:,
        drag_and_drop:,
        params:,
        current_user: user
      )
    ) do |box|
      box.with_header(**header_arguments) if header_arguments
      box.with_empty_state(title: "Sprint 1 is empty", description: "Drag work packages here")
      box.with_footer { footer_content } if footer_content
    end
  end

  describe "automatic work_packages iteration" do
    let(:work_packages) do
      [
        create(:work_package, subject: "WP A", project:, type: type_feature, status: default_status,
                              priority: default_priority, sprint:, position: 1),
        create(:work_package, subject: "WP B", project:, type: type_feature, status: default_status,
                              priority: default_priority, sprint:, position: 2)
      ]
    end

    it_behaves_like "rendering Box", row_count: 2, header: false, footer: false

    it "renders one row per work package" do
      expect(rendered_component).to have_text("WP A")
      expect(rendered_component).to have_text("WP B")
    end
  end

  describe "hardcoded Backlogs item component" do
    let(:work_packages) do
      [
        create(:work_package, subject: "Story card", project:, type: type_feature,
                              status: default_status, priority: default_priority,
                              sprint:, position: 1, story_points: 3)
      ]
    end

    it "renders items through Backlogs::WorkPackageCardListItemComponent" do
      work_package = work_packages.first

      expect(rendered_component).to have_css(
        ".Box-row#work_package_#{work_package.id}[data-controller='sortable-lists--item'] " \
        ".op-work-package-card[data-controller='backlogs--story']"
      )
    end

    it "renders Backlogs-specific row and card data attributes" do
      work_package = work_packages.first

      expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id}") do |row|
        expect(row["data-sortable-lists--item-id-value"]).to eq(work_package.id.to_s)
        expect(row["data-sortable-lists--item-type-value"]).to eq("work_package")
      end

      expect(rendered_component).to have_css(".Box-row#work_package_#{work_package.id} .op-work-package-card") do |card|
        expect(card["data-story"]).to be_present
        expect(card["data-backlogs--story-id-value"]).to eq(work_package.id.to_s)
        expect(card["data-sortable-lists--item-target"]).to eq("preview handle")
      end
    end

    it "renders the Backlogs work-package card" do
      work_package = work_packages.first

      expect(rendered_component).to have_css(
        ".Box-row#work_package_#{work_package.id} .sr-only",
        text: "3 story points"
      )
      expect(rendered_component).to have_element(
        "include-fragment",
        src: menu_project_backlogs_work_package_path(project, work_package)
      )
    end
  end

  describe "delegated header with fold-state defaults" do
    let(:header_arguments) { { title: "Sprint 1", count: 0 } }

    it "renders the header" do
      expect(rendered_component).to have_css(".Box-header")
    end

    it "keeps condensed row padding with spacious header padding" do
      expect(rendered_component).to have_css(
        ".Box.Box--condensed.op-border-box-list_header-padding-default"
      )
    end

    it "renders the provided title" do
      expect(rendered_component).to have_heading "Sprint 1", level: 4
    end

    it "announces dynamic counter updates" do
      expect(rendered_component).to have_css(
        ".Counter",
        aria: { label: I18n.t(:label_x_work_packages, count: 0), live: "polite" },
        visible: :all
      )
    end

    context "with work packages" do
      let(:header_arguments) { { title: "Sprint 1" } }
      let(:work_packages) do
        [
          create(:work_package, project:, type: type_feature, status: default_status,
                                priority: default_priority, sprint:, position: 1),
          create(:work_package, project:, type: type_feature, status: default_status,
                                priority: default_priority, sprint:, position: 2)
        ]
      end

      it "infers the count from the rendered work packages" do
        expect(rendered_component).to have_css(
          ".Counter",
          text: "2",
          aria: { label: I18n.t(:label_x_work_packages, count: 2) }
        )
      end
    end

    context "when the count is disabled" do
      let(:header_arguments) { { title: "Sprint 1", count: false } }
      let(:work_packages) do
        [
          create(:work_package, project:, type: type_feature, status: default_status,
                                priority: default_priority, sprint:, position: 1)
        ]
      end

      it "does not render the count" do
        expect(rendered_component).to have_no_css(".Counter")
      end
    end

    context "when the count label is overridden" do
      let(:header_arguments) do
        { title: "Sprint 1", count: 7, count_label: "7 backlog stories" }
      end

      it "renders the provided count and accessible label" do
        expect(rendered_component).to have_css(
          ".Counter",
          text: "7",
          aria: { label: "7 backlog stories" }
        )
      end
    end
  end

  describe "delegated footer" do
    let(:footer_content) { "footer-content" }

    it "renders the footer when supplied" do
      expect(rendered_component).to have_text("footer-content")
    end
  end

  describe "empty_state rendering" do
    it_behaves_like "rendering Blank Slate", heading: "Sprint 1 is empty"

    it "renders the blankslate when work_packages is empty" do
      expect(rendered_component).to have_text("Sprint 1 is empty")
      expect(rendered_component).to have_text("Drag work packages here")
    end

    it "announces dynamic empty-state updates" do
      expect(rendered_component).to have_role(:status, aria: { live: "polite" })
    end

    context "when work_packages is nil" do
      let(:work_packages) { nil }

      it "treats nil as an empty collection" do
        expect(rendered_component).to have_text("Sprint 1 is empty")
        expect(rendered_component).to have_text("Drag work packages here")
      end
    end

    context "when there are work packages" do
      let(:work_packages) do
        [
          create(:work_package, project:, type: type_feature, status: default_status,
                                priority: default_priority, sprint:, position: 1)
        ]
      end

      it "does not render the blankslate" do
        expect(rendered_component).to have_no_css(".blankslate")
      end
    end
  end

  describe "empty_state validation" do
    it "raises ArgumentError when work_packages is empty and no empty_state given" do
      expect do
        render_inline(
          described_class.new(
            work_packages: [],
            project:,
            container: sprint,
            current_user: user
          )
        ) do |box|
          box.with_footer { "" }
        end
      end.to raise_error(ArgumentError, /empty_state slot is required/)
    end
  end

  describe "drag-and-drop data merging" do
    context "without drag_and_drop" do
      it "does not emit drag-and-drop data" do
        expect(rendered_component).to have_no_css(".Box[data-sortable-lists-target]")
        expect(rendered_component).to have_no_css(".Box[data-sortable-lists-list-type]")
        expect(rendered_component).to have_no_css(".Box[data-sortable-lists-list-id]")
      end
    end

    context "with drag_and_drop configured" do
      let(:drag_and_drop) do
        { list_type: "sprint", list_id: sprint.id }
      end

      it "merges drag-and-drop data attributes onto the box" do
        expect(rendered_component).to have_css(".Box") do |box|
          expect(box["data-sortable-lists-target"]).to eq("list")
          expect(box["data-sortable-lists-list-type"]).to eq("sprint")
          expect(box["data-sortable-lists-list-id"]).to eq(sprint.id.to_s)
        end
      end
    end
  end

  describe "container/list/header DOM IDs" do
    context "when container is a Sprint" do
      let(:container) { sprint }

      it "uses dom_target(sprint) as the box id" do
        expect(rendered_component).to have_css(".Box#sprint_#{sprint.id}")
      end

      it "uses dom_target(sprint, :list) for the list id" do
        expect(rendered_component).to have_css("ul#sprint_#{sprint.id}_list")
      end
    end

    context "when container is a BacklogBucket" do
      let(:container) { backlog_bucket }

      it "uses dom_target(backlog_bucket) as the box id" do
        expect(rendered_component).to have_css(".Box#backlog_bucket_#{backlog_bucket.id}")
      end

      it "uses dom_target(backlog_bucket, :list) for the list id" do
        expect(rendered_component).to have_css("ul#backlog_bucket_#{backlog_bucket.id}_list")
      end
    end
  end
end
