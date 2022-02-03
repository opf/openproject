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

describe ::Storages::Storage, type: :model do
  let(:test_default_creator) { create(:user) }
  let(:test_default_attributes) do
    { name: "NC 1",
      provider_type: 'nextcloud',
      host: 'https://example.com',
      creator: test_default_creator }
  end

  describe '#create' do
    it "creates an instance" do
      storage = described_class.create test_default_attributes
      expect(storage).to be_valid
    end

    it "fails the validation if name is empty string" do
      expect(described_class.create(test_default_attributes.merge({ name: "" }))).to be_invalid
    end

    it "fails the validation if name is nil" do
      expect(described_class.create(test_default_attributes.merge({ name: nil }))).to be_invalid
    end

    it "fails the validation if host is empty string" do
      expect(described_class.create(test_default_attributes.merge({ host: '' }))).to be_invalid
    end

    it "fails the validation if host is nil" do
      expect(described_class.create(test_default_attributes.merge({ host: nil }))).to be_invalid
    end

    context "when having already one instance" do
      let(:old_storage) { described_class.create test_default_attributes }

      before do
        old_storage
      end

      it "fails the validation if name is not unique" do
        expect(described_class.create(test_default_attributes.merge({ host: 'https://example2.com' }))).to be_invalid
      end

      it "fails the validation if host is not unique" do
        expect(described_class.create(test_default_attributes.merge({ name: 'NC 2' }))).to be_invalid
      end
    end
  end

  describe '#destroy' do
    let(:project) { create(project) }
    let(:storage) { described_class.create(test_default_attributes) }
    let(:project_storage) { Storages::ProjectStorage.create(project: project, storage: storage) }
    let(:work_package) { create(:work_package, project: project) }
    let(:file_link) { FileLink.create(container: work_package, storage: storage) }

    before do
      storage.destroy
    end

    it "destroys all associated ProjectStorage and FileLink records" do
      expect(Storages::ProjectStorage.count).to be 0
      expect(Storages::FileLink.count).to be 0
    end
  end
end
