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

require "spec_helper"

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter do
  let(:custom_field) { build(:custom_field) }
  let(:schema) do
    API::V3::WorkPackages::Schema::SpecificWorkPackageSchema.new(work_package:)
  end
  let(:representer) { described_class.create(schema, self_link: nil, current_user:) }
  let(:work_package) { build_stubbed(:work_package, type: build_stubbed(:type)) }

  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project :edit_work_packages, project: work_package.project
    end

    login_as(current_user)

    allow(schema.project).to receive(:backlogs_enabled?).and_return(true)
    allow(work_package.type).to receive(:story?).and_return(true)
    allow(work_package).to receive(:leaf?).and_return(true)
  end

  describe "storyPoints" do
    subject { representer.to_json }

    it_behaves_like "has basic schema properties" do
      let(:path) { "storyPoints" }
      let(:type) { "Integer" }
      let(:name) { I18n.t("activerecord.attributes.work_package.story_points") }
      let(:required) { false }
      let(:writable) { true }
    end

    context "when backlogs module is disabled" do
      before do
        allow(schema.project).to receive(:backlogs_enabled?).and_return(false)
      end

      it "does not show story points" do
        expect(subject).not_to have_json_path("storyPoints")
      end
    end

    context "not a story" do
      before do
        allow(schema.type).to receive(:story?).and_return(false)
      end

      it "does not show story points" do
        expect(subject).not_to have_json_path("storyPoints")
      end
    end
  end
end
