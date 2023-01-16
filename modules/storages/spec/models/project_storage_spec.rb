#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require_relative '../spec_helper'

describe Storages::ProjectStorage do
  let(:creator) { create(:user) }
  let(:project) { create(:project, enabled_module_names: %i[storages work_packages]) }
  let(:storage) { create(:storage) }
  let(:attributes) do
    {
      storage:,
      creator:,
      project:
    }
  end

  describe '#create' do
    it "creates an instance" do
      project_storage = described_class.create attributes
      expect(project_storage).to be_valid
    end

    context "when having already one instance" do
      let(:old_project_storage) { described_class.create attributes }

      before do
        old_project_storage
      end

      it "fails if it is not unique per storage and project" do
        expect(described_class.create(attributes.merge)).to be_invalid
      end
    end
  end

  describe '#destroy' do
    let(:project_storage_to_destroy) { described_class.create(attributes) }
    let(:work_package) { create(:work_package, project:) }
    let(:file_link) { create(:file_link, storage:, container_id: work_package.id) }

    before do
      project_storage_to_destroy
      file_link

      project_storage_to_destroy.destroy
    end

    it "does not destroy associated FileLink records" do
      expect(Storages::ProjectStorage.count).to eq 0
      expect(Storages::FileLink.count).not_to eq 0
    end
  end
end
