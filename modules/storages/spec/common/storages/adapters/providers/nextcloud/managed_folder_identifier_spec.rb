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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Storages::Adapters::Providers::Nextcloud::ManagedFolderIdentifier do
  let(:managed_folder_identifier) { described_class.new(project_storage) }

  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:project) { create(:project, name: project_name) }
  let(:project_name) { "My great Demo project" }
  let(:storage) { create(:nextcloud_storage) }

  describe "#path" do
    subject { managed_folder_identifier.path }

    it { is_expected.to eq("/OpenProject/My great Demo project (#{project.id})/") }

    context "when the project name contains a slash" do
      let(:project_name) { "My great/awesome project" }

      it { is_expected.to eq("/OpenProject/My great|awesome project (#{project.id})/") }

      context "when the pipe character is prohibited by the storage" do
        let(:storage) { create(:nextcloud_storage, forbidden_file_name_characters: "|") }

        it { is_expected.to eq("/OpenProject/My great_awesome project (#{project.id})/") }
      end
    end

    context "when the project name contains a backslash" do
      let(:project_name) { "My great\\awesome project" }

      it { is_expected.to eq("/OpenProject/My great|awesome project (#{project.id})/") }

      context "when the pipe character is prohibited by the storage" do
        let(:storage) { create(:nextcloud_storage, forbidden_file_name_characters: "|") }

        it { is_expected.to eq("/OpenProject/My great_awesome project (#{project.id})/") }
      end
    end

    context "when the project name contains special characters" do
      let(:project_name) { "My $pecia| project: The ☃" }

      it { is_expected.to eq("/OpenProject/My $pecia| project: The ☃ (#{project.id})/") }

      context "and when certain characters are prohibited by the storage" do
        let(:storage) { create(:nextcloud_storage, forbidden_file_name_characters: "$:") }

        it { is_expected.to eq("/OpenProject/My _pecia| project_ The ☃ (#{project.id})/") }
      end
    end
  end
end
