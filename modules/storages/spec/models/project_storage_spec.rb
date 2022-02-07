#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

describe ::Storages::ProjectStorage, type: :model do
  let(:creator) { create(:user) }
  let(:project) { create(:project, :enabled_module_names => %i[storages work_packages]) }
  let(:storage) { create(:storage) }
  let(:attributes) do
    {
      storage: storage,
      creator: creator,
      project: project}
  end

  describe '#create' do
    it "creates an instance" do
      project_storage = described_class.create attributes
      expect(project_storage).to be_valid
    end

    it "create instance should fail with wrong creator object" do
      file_link = described_class.create(attributes.merge({ creator_id: project.id }))
      expect(file_link).to be_invalid
    end
  end

  describe '#destroy' do
    let(:project_storage_to_destroy) { described_class.create(attributes) }

    before do
      project_storage_to_destroy.destroy
    end

    it "destroy instance should leave no file_link" do
      expect(Storages::ProjectStorage.count).to be 0
    end
  end
end
