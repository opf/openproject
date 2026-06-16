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

RSpec.describe "API v3 BacklogBucket resource on project", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:other_project) { create(:project, public: false) }

  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:other_bucket) { create(:backlog_bucket, project: other_project) }

  let(:permissions) { %i[view_sprints] }

  current_user do
    create(:user, member_with_permissions: { project => permissions })
  end

  describe "GET /api/v3/projects/:id/backlog_buckets" do
    let(:get_path) { api_v3_paths.project_backlog_buckets(project.id) }

    before { get get_path }

    context "for a user with view_sprints permission" do
      it_behaves_like "API V3 collection response", 1, 1, "BacklogBucket" do
        let(:elements) { [bucket] }
      end
    end

    context "for a user without view_sprints permission" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end

    context "for a user being not a project member at all" do
      let(:get_path) { api_v3_paths.project_backlog_buckets(other_project.id) }

      it_behaves_like "not found"
    end
  end
end
