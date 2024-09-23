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
require_module_spec_helper

RSpec.describe API::V3::ProjectStorages::ProjectStorageRepresenter do
  include API::V3::Utilities::PathHelper
  include EnsureConnectionPathHelper

  let(:user) { build_stubbed(:user) }

  let(:project_storage) { build_stubbed(:project_storage, project_folder_mode: "manual", project_folder_id: "1337") }

  let(:representer) { described_class.new(project_storage, current_user: user) }

  subject { representer.to_json }

  before do
    allow(user).to receive("allowed_in_project?").and_return(true)
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { representer._type }
    end

    it_behaves_like "property", :id do
      let(:value) { project_storage.id }
    end

    it_behaves_like "datetime property", :createdAt do
      let(:value) { project_storage.created_at }
    end

    it_behaves_like "datetime property", :updatedAt do
      let(:value) { project_storage.updated_at }
    end

    it_behaves_like "property", :projectFolderMode do
      let(:value) { project_storage.project_folder_mode }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "storage" }
      let(:href) { api_v3_paths.storage(project_storage.storage.id) }
      let(:title) { project_storage.storage.name }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "project" }
      let(:href) { api_v3_paths.project(project_storage.project.id) }
      let(:title) { project_storage.project.name }
    end

    it_behaves_like "has a titled link" do
      let(:link) { "creator" }
      let(:href) { api_v3_paths.user(project_storage.creator.id) }
      let(:title) { project_storage.creator.name }
    end

    it_behaves_like "has an untitled link" do
      let(:link) { "projectFolder" }
      let(:href) { api_v3_paths.storage_file(project_storage.storage.id, project_storage.project_folder_id) }
    end

    it_behaves_like "has an untitled link" do
      let(:link) { "open" }
      let(:href) { api_v3_paths.project_storage_open(project_storage.id) }
    end

    context "when storage is not configured" do
      it_behaves_like "has an untitled link" do
        let(:link) { "openWithConnectionEnsured" }
        let(:href) { nil }
      end
    end

    context "when storage is configured" do
      before { project_storage.storage = create(:nextcloud_storage_configured) }

      it_behaves_like "has an untitled link" do
        let(:link) { "openWithConnectionEnsured" }
        let(:href) { ensure_connection_path(project_storage) }
      end
    end

    context "when user does not have read_files permission" do
      let(:project_storage) { build_stubbed(:project_storage, project_folder_mode: "automatic", project_folder_id: "1337") }

      before do
        allow(user).to receive("allowed_in_project?").and_return(false)
      end

      it_behaves_like "has no link" do
        let(:link) { "openWithConnectionEnsured" }
      end

      it_behaves_like "has no link" do
        let(:link) { "open" }
      end
    end
  end
end
