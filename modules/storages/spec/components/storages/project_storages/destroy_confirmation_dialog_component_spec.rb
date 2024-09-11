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
#
require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::ProjectStorages::DestroyConfirmationDialogComponent,
               type: :component do
  describe "#heading" do
    it "contains the storage name" do
      storage = build_stubbed(:one_drive_storage)
      project_storage = build_stubbed(:project_storage, storage:)

      component = described_class.new(storage:, project_storage:)
      expect(component.heading).to include(storage.name)
    end
  end

  describe "#text" do
    let(:storage) { build_stubbed(:storage, :as_generic) }

    context "for a project with automatically managed project folder" do
      it "includes an additional hint for data loss" do
        project_storage = build_stubbed(:project_storage, storage:, project_folder_mode: "automatic")
        component = described_class.new(storage:, project_storage:)
        expect(component.text).to include("irreversible")
        expect(component.text).to include("files will be deleted forever")
      end
    end

    context "for a project with manual managed folder" do
      it "includes only the basic hint" do
        project_storage = build_stubbed(:project_storage, storage:, project_folder_mode: "manual")
        component = described_class.new(storage:, project_storage:)
        expect(component.text).to include("irreversible")
        expect(component.text).not_to include("files will be deleted forever")
      end
    end

    context "for a project with unmanaged folder" do
      it "includes only the basic hint" do
        project_storage = build_stubbed(:project_storage, storage:, project_folder_mode: "inactive")
        component = described_class.new(storage:, project_storage:)
        expect(component.text).to include("irreversible")
        expect(component.text).not_to include("files will be deleted forever")
      end
    end
  end
end
