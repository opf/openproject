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
require "rack/test"

RSpec.describe "GET workspaces/:id/labels", with_flag: :work_package_labels do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, public: false) }
  shared_let(:other_project) { create(:project) }
  shared_let(:permitted_user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }
  shared_let(:unpermitted_user) { create(:user, member_with_permissions: { project => [] }) }

  shared_let(:popular_elsewhere) { create(:label, name: "popular elsewhere") }
  shared_let(:local_label) { create(:label, name: "local") }
  shared_let(:unused_label) { create(:label, name: "unused") }

  before_all do
    create_list(:work_package, 2, project: other_project).each { create(:labeling, label: popular_elsewhere, labelable: it) }
    create(:labeling, label: local_label, labelable: create(:work_package, project:))
  end

  subject(:response) { last_response }

  shared_context "with labels by workspace" do
    context "for a user with permission to view work packages" do
      current_user { permitted_user }

      before do
        get get_path
      end

      it_behaves_like "API V3 collection response", 3, 3, "Label" do
        let(:elements) { [local_label, popular_elsewhere, unused_label] }
      end
    end

    context "with a name filter" do
      current_user { permitted_user }

      before do
        filter = [{ name: { operator: "~", values: ["popular"] } }]

        get "#{get_path}?filters=#{CGI.escape(filter.to_json)}"
      end

      it_behaves_like "API V3 collection response", 1, 1, "Label" do
        let(:elements) { [popular_elsewhere] }
      end
    end

    context "with a page size smaller than the number of labels" do
      current_user { permitted_user }

      before do
        get "#{get_path}?pageSize=2"
      end

      it_behaves_like "API V3 collection response", 3, 2, "Label" do
        let(:elements) { [local_label, popular_elsewhere] }
      end

      it "links to the next page" do
        expect(response.body).to have_json_path("_links/nextByOffset/href")
      end
    end

    context "with pageSize -1 requesting the maximum page size" do
      current_user { permitted_user }

      before do
        get "#{get_path}?pageSize=-1"
      end

      it_behaves_like "API V3 collection response", 3, 3, "Label" do
        let(:elements) { [local_label, popular_elsewhere, unused_label] }
      end

      it "resolves to the configured maximum page size" do
        expect(response.body).to be_json_eql(Setting.apiv3_max_page_size.to_i.to_json).at_path("pageSize")
      end
    end

    context "for a user without permission to view work packages" do
      current_user { unpermitted_user }

      before do
        get get_path
      end

      it_behaves_like "unauthorized access"
    end

    context "with the feature flag inactive", with_flag: { work_package_labels: false } do
      current_user { permitted_user }

      before do
        get get_path
      end

      it_behaves_like "not found"
    end
  end

  context "for workspaces/:id/labels" do
    let(:get_path) { api_v3_paths.labels_by_workspace project.id }

    include_context "with labels by workspace"
  end
end
