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

RSpec.shared_examples_for "base storage" do
  let(:default_attributes) do
    {
      name: "My storage",
      host: "https://example.com",
      creator: create(:user)
    }
  end

  describe ".shorten_provider_type" do
    context "when provider_type matches the signature" do
      it "responds with shortened provider type" do
        expect(
          described_class.shorten_provider_type(described_class::PROVIDER_TYPE_NEXTCLOUD)
        ).to eq("nextcloud")
        expect(
          described_class.shorten_provider_type(described_class::PROVIDER_TYPE_ONE_DRIVE)
        ).to eq("one_drive")
      end
    end

    context "when provider_type does not match the signature" do
      it "raises an error", :aggregate_failures do
        expect do
          described_class.shorten_provider_type("Storages::Nextcloud")
        end.to raise_error("Unknown provider_type! Given: Storages::Nextcloud. " \
                           "Expected the following signature: Storages::{Name of the provider}Storage")
        expect do
          described_class.shorten_provider_type("Storages:NextcloudStorage")
        end.to raise_error("Unknown provider_type! Given: Storages:NextcloudStorage. " \
                           "Expected the following signature: Storages::{Name of the provider}Storage")
        expect do
          described_class.shorten_provider_type("Storages::NextcloudStorag")
        end.to raise_error("Unknown provider_type! Given: Storages::NextcloudStorag. " \
                           "Expected the following signature: Storages::{Name of the provider}Storage")
      end
    end
  end

  describe "#create" do
    it "creates an instance" do
      storage = described_class.create default_attributes
      expect(storage).to be_valid
    end

    context "with one instance already present" do
      let(:old_storage) { described_class.create default_attributes }

      before do
        old_storage
      end

      it "fails the validation if name is not unique" do
        expect(described_class.create(default_attributes.merge({ host: "https://example2.com" }))).not_to be_valid
      end

      it "fails the validation if host is not unique" do
        expect(described_class.create(default_attributes.merge({ name: "Another storage" }))).not_to be_valid
      end
    end
  end

  describe "#destroy" do
    let(:project) { create(:project) }
    let(:storage) { described_class.create(default_attributes) }
    let(:project_storage) { create(:project_storage, project:, storage:, creator: create(:user)) }
    let(:work_package) { create(:work_package, project:) }
    let(:file_link) { create(:file_link, storage:, container_id: work_package.id) }

    before do
      project_storage
      file_link

      storage.destroy
    end

    it "destroys all associated ProjectStorage and FileLink records" do
      expect(Storages::ProjectStorage.count).to be 0
      expect(Storages::FileLink.count).to be 0
    end
  end
end
