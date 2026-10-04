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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe API::V3::ProjectStorages::ProjectStorageRepresenter do
  include API::V3::Utilities::PathHelper
  include EnsureConnectionPathHelper

  let(:current_user) { build_stubbed(:user) }

  let(:workspace) { build_stubbed(:project) }
  let(:project_storage) do
    build_stubbed(:project_storage, project: workspace, project_folder_mode: "manual", project_folder_id: "1337")
  end

  let(:representer) { described_class.new(project_storage, current_user:) }
  let(:user_allowed_in_project) { true }

  subject { representer.to_json }

  before do
    allow(current_user).to receive("allowed_in_project?").and_return(user_allowed_in_project)
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
  end

  describe "_links" do
    it_behaves_like "has a titled link" do
      let(:link) { "storage" }
      let(:href) { api_v3_paths.storage(project_storage.storage.id) }
      let(:title) { project_storage.storage.name }
    end

    it_behaves_like "has workspace linked"

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

    it_behaves_like "has an untitled link" do
      let(:link) { "openWithConnectionEnsured" }
      let(:href) { api_v3_paths.project_storage_open(project_storage.id) }
    end

    context "when user does not have read_files permission" do
      let(:project_storage) { build_stubbed(:project_storage, project_folder_mode: "automatic", project_folder_id: "1337") }
      let(:user_allowed_in_project) { false }

      it_behaves_like "has no link" do
        let(:link) { "openWithConnectionEnsured" }
      end

      it_behaves_like "has no link" do
        let(:link) { "open" }
      end
    end

    describe "_embedded" do
      describe "project" do
        let(:embedded_path) { "_embedded/project" }

        it_behaves_like "has the resource not embedded"
      end
    end
  end
end
