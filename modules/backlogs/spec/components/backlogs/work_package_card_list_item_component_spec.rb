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

RSpec.describe Backlogs::WorkPackageCardListItemComponent, type: :component do
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
  let(:params) { {} }
  let(:work_package) do
    create(:work_package,
           project:,
           type: type_feature,
           status: default_status,
           priority: default_priority,
           subject: "Card subject",
           story_points: 5,
           position: 1,
           sprint:)
  end
  let(:item) do
    described_class.new(work_package:, project:, container:, params:, current_user: user)
  end

  describe "#row_args" do
    it "marks the row as clickable and controlled by the Backlogs story controller" do
      expect(item.row_args[:classes]).to include(
        "Box-row--hover-blue",
        "Box-row--focus-gray",
        "Box-row--clickable"
      )
      expect(item.row_args[:data]).to include(
        story: true,
        controller: "backlogs--story",
        backlogs__story_id_value: work_package.id,
        backlogs__story_display_id_value: work_package.display_id,
        backlogs__story_full_url_value: work_package_path(work_package),
        backlogs__story_selected_class: "Box-row--blue"
      )
      expect(item.row_args[:test_selector]).to eq("work-package-#{work_package.id}")
    end

    it "marks the row as draggable for users allowed to manage sprint items" do
      expect(item.row_args[:classes]).to include("Box-row--draggable")
      expect(item.row_args[:data]).to include(
        draggable_id: work_package.id,
        draggable_type: "story"
      )
    end

    context "when the user cannot manage sprint items" do
      let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages]) }
      let(:limited_user) { create(:user, member_with_roles: { project => role }) }
      let(:item) do
        described_class.new(work_package:, project:, container:, params:, current_user: limited_user)
      end

      it "does not mark the row as draggable" do
        expect(item.row_args[:classes]).not_to include("Box-row--draggable")
        expect(item.row_args[:data]).not_to include(:draggable_id)
        expect(item.row_args[:data]).not_to include(:drop_url)
      end
    end
  end

  describe "URL derivation by container" do
    context "with a sprint container" do
      it "sets drop_url and split_url" do
        expect(item.row_args.dig(:data, :backlogs__story_split_url_value))
          .to end_with(project_backlogs_backlog_details_path(project, work_package))
        expect(item.row_args.dig(:data, :drop_url))
          .to end_with(move_project_backlogs_work_package_path(project, work_package))
      end
    end

    context "with a backlog bucket container" do
      let(:container) { backlog_bucket }

      it "sets drop_url" do
        expect(item.row_args.dig(:data, :drop_url))
          .to end_with(move_project_backlogs_work_package_path(project, work_package))
      end
    end

    context "with an inbox container id" do
      let(:container) { "inbox_project_#{project.id}" }

      it "sets drop_url" do
        expect(item.row_args.dig(:data, :drop_url))
          .to end_with(move_project_backlogs_work_package_path(project, work_package))
      end
    end

    context "with params" do
      let(:params) { { all: 1 } }

      it "passes params into row URLs" do
        expect(item.row_args.dig(:data, :backlogs__story_split_url_value)).to match(/all=1/)
        expect(item.row_args.dig(:data, :drop_url)).to match(/all=1/)
      end
    end
  end

  describe "#card" do
    subject(:rendered_card) { render_inline(item.card) }

    it "builds a Backlogs card with story points" do
      expect(rendered_card).to have_css("span", text: "5", aria: { hidden: true })
      expect(rendered_card).to have_css(".sr-only", text: "5 story points")
    end

    it "supports caller-provided metric content through the item" do
      item.with_metric { "Custom metric" }

      expect(rendered_card).to have_text("Custom metric")
      expect(rendered_card).to have_no_css(".sr-only", text: "5 story points")
    end

    context "with a sprint container" do
      it "uses the work package menu source" do
        expect(rendered_card).to have_element(
          "include-fragment",
          src: menu_project_backlogs_work_package_path(project, work_package)
        )
      end
    end

    context "with an inbox container id" do
      let(:container) { "inbox_project_#{project.id}" }

      it "uses the work package menu source" do
        expect(rendered_card).to have_element(
          "include-fragment",
          src: menu_project_backlogs_work_package_path(project, work_package)
        )
      end
    end

    context "with a backlog bucket container" do
      let(:container) { backlog_bucket }

      it "uses the work package menu source" do
        expect(rendered_card).to have_element(
          "include-fragment",
          src: menu_project_backlogs_work_package_path(project, work_package)
        )
      end
    end

    context "with params" do
      let(:params) { { all: 1 } }

      it "passes params into the menu source" do
        expect(rendered_card).to have_element(
          "include-fragment",
          src: menu_project_backlogs_work_package_path(project, work_package, all: 1)
        )
      end
    end
  end
end
