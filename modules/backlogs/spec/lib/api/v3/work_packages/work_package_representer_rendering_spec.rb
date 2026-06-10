# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

# Only tests the links/properties added by the backlogs plugin. It does not retest the properties already
# covered in the core.
RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    build_stubbed(:work_package,
                  type:,
                  project:,
                  story_points:,
                  position:,
                  sprint:,
                  backlog_bucket:)
  end
  let(:type) { build_stubbed(:type) }
  let(:enabled_module_names) { %w[backlogs] }
  let(:project) do
    build_stubbed(:project, enabled_module_names:)
  end

  let(:story_points) { 23 }
  let(:position) { 123 }
  let(:sprint) { build_stubbed(:sprint) }
  let(:backlog_bucket) { build_stubbed(:backlog_bucket) }
  let(:embed_links) { true }
  let(:representer) do
    described_class.create(work_package, current_user:, embed_links:)
  end
  let(:permissions) { %i[view_sprints] }

  subject(:generated) { representer.to_json }

  include_context "eager loaded work package representer"

  current_user { build_stubbed(:user) }

  before do
    if project.present?
      mock_permissions_for(current_user) do |mock|
        permissions.each do |permission|
          mock.allow_in_project(*permission, project:)
        end
      end
    end
  end

  describe "properties" do
    describe "storyPoints" do
      it_behaves_like "property", :storyPoints do
        let(:value) { story_points }
      end

      context "when backlogs is disabled" do
        let(:enabled_module_names) { [] }

        it_behaves_like "no property", :storyPoints
      end
    end

    describe "position" do
      it_behaves_like "property", :position do
        let(:value) { position }
      end

      context "when backlogs is disabled" do
        let(:enabled_module_names) { [] }

        it_behaves_like "no property", :position
      end
    end
  end

  describe "links" do
    describe "sprint" do
      let(:link) { "sprint" }
      let(:href) { api_v3_paths.sprint(sprint.id) }
      let(:title) { sprint.name }

      it_behaves_like "has a titled link"

      context "when lacking the permission" do
        let(:permissions) { [] }

        it_behaves_like "has no link"
      end

      context "when the project is empty (because the work package is not persisted yet)" do
        let(:project) { nil }

        it_behaves_like "has no link"
      end

      context "when the work package has no backlog bucket assigned" do
        let(:sprint) { nil }

        it_behaves_like "has an empty link" do
          let(:link) { "sprint" }
        end
      end
    end

    describe "backlogBucket" do
      let(:link) { "backlogBucket" }
      let(:href) { api_v3_paths.backlog_bucket(backlog_bucket.id) }
      let(:title) { backlog_bucket.name }

      it_behaves_like "has a titled link"

      context "when lacking the permission" do
        let(:permissions) { [] }

        it_behaves_like "has no link"
      end

      context "when the project is empty (because the work package is not persisted yet)" do
        let(:project) { nil }

        it_behaves_like "has no link"
      end

      context "when the work package has no backlog bucket assigned" do
        let(:backlog_bucket) { nil }

        it_behaves_like "has an empty link" do
          let(:link) { "backlogBucket" }
        end
      end
    end

    describe "update links" do
      context "when user lacks edit permission but has manage_sprint_items" do
        let(:permissions) { super() + [:manage_sprint_items] }

        it_behaves_like "has an untitled link" do
          let(:link) { "update" }
          let(:href) { api_v3_paths.work_package_form(work_package.id) }
        end

        it_behaves_like "has an untitled link" do
          let(:link) { "updateImmediately" }
          let(:href) { api_v3_paths.work_package(work_package.id) }
        end
      end
    end
  end

  describe "embedded" do
    describe "sprint" do
      let(:embedded_path) { "_embedded/sprint" }
      let(:embedded_resource) { sprint }
      let(:embedded_resource_type) { "Sprint" }

      it_behaves_like "has the resource embedded"

      context "when lacking the permission" do
        let(:permissions) { [] }

        it_behaves_like "has the resource not embedded"
      end

      context "when the work package has no sprint assigned" do
        let(:sprint) { nil }

        it_behaves_like "has the resource not embedded"
      end
    end

    describe "backlogBucket" do
      let(:embedded_path) { "_embedded/backlogBucket" }
      let(:embedded_resource) { backlog_bucket }
      let(:embedded_resource_type) { "BacklogBucket" }

      it_behaves_like "has the resource embedded"

      context "when lacking the permission" do
        let(:permissions) { [] }

        it_behaves_like "has the resource not embedded"
      end

      context "when the work package has no backlog bucket assigned" do
        let(:backlog_bucket) { nil }

        it_behaves_like "has the resource not embedded"
      end
    end
  end
end
