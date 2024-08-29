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

require "contracts/shared/model_contract_shared_context"

RSpec.describe Storages::ProjectStorages::BaseContract do
  include_context "ModelContract shared context"

  RSpec.shared_examples_for "a ProjectStorage BaseContract" do
    context "if the project folder mode is `inactive`" do
      before do
        project_storage.project_folder_mode = "inactive"
      end

      it_behaves_like "contract is valid"
    end

    context "if the project folder mode is `automatic`" do
      before do
        project_storage.project_folder_mode = "automatic"
        project_storage.storage.automatic_management_enabled = true
      end

      it_behaves_like "contract is valid"
    end

    context "when the project folder mode is `automatic` but the storage is not automatically managed" do
      before do
        project_storage.project_folder_mode = "automatic"
        project_storage.storage.automatic_management_enabled = false
      end

      it_behaves_like "contract is invalid", project_folder_mode: :mode_unavailable
    end

    context "if the project folder mode is `manual`" do
      before do
        project_storage.project_folder_mode = "manual"
      end

      context "with no project_folder_id" do
        it_behaves_like "contract is invalid", project_folder_id: :blank
      end

      context "with project_folder_id" do
        before do
          project_storage.project_folder_id = "Project#1"
        end

        it_behaves_like "contract is valid"
      end
    end

    include_examples "contract reuses the model errors"
  end

  describe "For a nextcloud storage" do
    let(:contract) { described_class.new(project_storage, build_stubbed(:admin)) }
    let(:storage) { build_stubbed(:nextcloud_storage) }
    let(:project_storage) { build(:project_storage, storage:) }

    it_behaves_like "a ProjectStorage BaseContract"

    context "when the project folder mode is `manual` but the storage is automatically managed" do
      before do
        project_storage.project_folder_id = "Project#1"
        project_storage.project_folder_mode = "manual"
        project_storage.storage.automatic_management_enabled = true
      end

      it_behaves_like "contract is valid"
    end
  end

  describe "For a one drive storage" do
    let(:contract) { described_class.new(project_storage, build_stubbed(:admin)) }
    let(:storage) { build_stubbed(:one_drive_storage) }
    let(:project_storage) { build(:project_storage, storage:) }

    it_behaves_like "a ProjectStorage BaseContract"

    context "when the project folder mode is `manual` but the storage is automatically managed" do
      before do
        project_storage.project_folder_mode = "manual"
        project_storage.storage.automatic_management_enabled = true
      end

      it_behaves_like "contract is invalid", project_folder_mode: :mode_unavailable
    end
  end
end
