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

require "spec_helper"

# Only tests the links added by the GitHub integration.
RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:project) { build_stubbed(:project) }
  let(:type) { build_stubbed(:type) }
  let(:work_package) { build_stubbed(:work_package, project:, type:) }
  let(:representer) do
    described_class.create(work_package, current_user:, embed_links: true)
  end

  subject(:generated) { representer.to_json }

  include_context "eager loaded work package representer"

  current_user { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(:view_work_packages, :show_github_content, project:)
    end
  end

  describe "links" do
    context "for a persisted work package" do
      it_behaves_like "has a titled link" do
        let(:link) { "github" }
        let(:href) { "#{Rails.application.routes.url_helpers.work_package_path(id: work_package.id)}/tabs/github" }
        let(:title) { "github" }
      end

      it_behaves_like "has a titled link" do
        let(:link) { "github_pull_requests" }
        let(:href) { api_v3_paths.github_pull_requests_by_work_package(work_package.id) }
        let(:title) { "GitHub pull requests" }
      end
    end

    context "for a new work package" do
      let(:work_package) { build(:work_package, project:, type:) }

      it "has no github link" do
        expect(subject).not_to have_json_path("_links/github")
      end

      it "has no github_pull_requests link" do
        expect(subject).not_to have_json_path("_links/github_pull_requests")
      end
    end
  end
end
