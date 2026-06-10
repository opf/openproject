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

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:custom_field) { build(:custom_field) }
  let(:schema) do
    API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:)
  end
  let(:representer) { described_class.create(schema, form_embedded: true, self_link: nil, current_user:) }
  let(:backlogs_enabled) { true }
  let(:project) do
    work_package.project.tap do |p|
      allow(p).to receive(:backlogs_enabled?).and_return(backlogs_enabled)
    end
  end
  let(:work_package_type) { build_stubbed(:type, attribute_groups: [["Agile", %w[position sprint story_points backlog_bucket]]]) }
  let(:work_package) { build_stubbed(:work_package, type: work_package_type) }

  let(:current_user) { build_stubbed(:user) }
  let(:permissions) { %i(view_work_packages edit_work_packages view_sprints manage_sprint_items) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project:
    end

    login_as(current_user)
  end

  subject { representer.to_json }

  describe "storyPoints" do
    it_behaves_like "has basic schema properties" do
      let(:path) { "storyPoints" }
      let(:type) { "Integer" }
      let(:name) { I18n.t("activerecord.attributes.work_package.story_points") }
      let(:required) { false }
      let(:writable) { true }
    end

    context "when backlogs module is disabled" do
      let(:backlogs_enabled) { false }

      it "does not show story points" do
        expect(subject).not_to have_json_path("storyPoints")
      end
    end
  end

  describe "position" do
    it_behaves_like "has basic schema properties" do
      let(:path) { "position" }
      let(:type) { "Integer" }
      let(:name) { I18n.t("activerecord.attributes.work_package.position") }
      let(:required) { false }
      let(:writable) { false }
    end

    context "when backlogs module is disabled" do
      let(:backlogs_enabled) { false }

      it "does not show position" do
        expect(subject).not_to have_json_path("position")
      end
    end
  end

  describe "sprint" do
    let(:path) { "sprint" }

    it_behaves_like "has basic schema properties" do
      let(:type) { "Sprint" }
      let(:name) { I18n.t("activerecord.attributes.work_package.sprint") }
      let(:required) { false }
      let(:writable) { true }
      let(:location) { "_links" }
    end

    it_behaves_like "links to allowed values via collection link" do
      let(:filters) do
        CGI.escape(JSON.dump([{ status: { operator: "!", values: [Sprint.statuses["completed"]] } }]))
      end
      let(:href) { "#{api_v3_paths.project_sprints(project.id)}?filters=#{filters}&pageSize=-1" }
    end

    context "when lacking permission to set the sprint" do
      let(:permissions) { %i(view_work_packages edit_work_packages view_sprints) }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Sprint" }
        let(:name) { I18n.t("activerecord.attributes.work_package.sprint") }
        let(:required) { false }
        let(:writable) { false }
        let(:location) { "_links" }
      end
    end

    context "when lacking permission to see the sprints (or if backlogs is disabled)" do
      let(:permissions) { %i(view_work_packages edit_work_packages) }

      it "has no reference to the sprint" do
        expect(subject).not_to have_json_path(path)
      end
    end
  end

  describe "backlogBucket" do
    let(:path) { "backlogBucket" }

    it_behaves_like "has basic schema properties" do
      let(:type) { "BacklogBucket" }
      let(:name) { I18n.t("activerecord.attributes.work_package.backlog_bucket") }
      let(:required) { false }
      let(:writable) { true }
      let(:location) { "_links" }
    end

    it_behaves_like "links to allowed values via collection link" do
      let(:href) { "#{api_v3_paths.project_backlog_buckets(project.id)}?filters=%5B%5D&pageSize=-1" }
    end

    context "when lacking permission to see the sprints (or if backlogs is disabled)" do
      let(:permissions) { %i(view_work_packages edit_work_packages) }

      it "has no reference to the backlog bucket" do
        expect(subject).not_to have_json_path(path)
      end
    end

    context "when lacking permission to set the backlog bucket" do
      let(:permissions) { %i(view_work_packages edit_work_packages view_sprints) }

      it_behaves_like "has basic schema properties" do
        let(:type) { "BacklogBucket" }
        let(:name) { I18n.t("activerecord.attributes.work_package.backlog_bucket") }
        let(:required) { false }
        let(:writable) { false }
        let(:location) { "_links" }
      end
    end
  end

  describe "attribute_groups" do
    context "with backlogs enabled" do
      it "has backlogs properties listed in the right group" do
        expect(subject).to be_json_eql(%w[position sprint storyPoints backlogBucket])
                             .at_path("_attributeGroups/0/attributes")
      end
    end

    context "with backlogs enabled and permissions missing" do
      let(:permissions) { %i(view_work_packages edit_work_packages) }

      it "has backlogs properties listed in the right group" do
        expect(subject).to be_json_eql(%w[position sprint storyPoints backlogBucket])
                             .at_path("_attributeGroups/0/attributes")
      end
    end

    context "with backlogs disabled" do
      let(:backlogs_enabled) { false }

      it "lacks the backlogs properties" do
        expect(subject).to be_json_eql(%w[])
                             .at_path("_attributeGroups/0/attributes")
      end
    end
  end
end
