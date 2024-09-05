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

RSpec.describe Storages::ProjectStorages::NotificationsService do
  shared_let(:project_storage) { create(:project_storage, :as_automatically_managed) }

  before do
    allow(OpenProject::Notifications).to receive(:send)
  end

  shared_examples "broadcasts the project storage event" do |event|
    it "broadcasts the project storage event #{event}" do
      expect(OpenProject::Notifications).to have_received(:send)
        .with(event, project_folder_mode: project_storage.project_folder_mode.to_sym,
                     project_folder_mode_previously_was: project_storage.project_folder_mode_previously_was&.to_sym,
                     storage: project_storage.storage)
    end
  end

  %i[created destroyed].each do |event|
    describe ".broadcast_project_storage_#{event}" do
      before { described_class.public_send(:"broadcast_project_storage_#{event}", project_storage:) }

      it_behaves_like "broadcasts the project storage event",
                      OpenProject::Events.const_get("PROJECT_STORAGE_#{event.to_s.upcase}")
    end
  end

  describe ".broadcast_project_storage_updated" do
    before do
      project_storage.update(project_folder_mode: "inactive")
      described_class.broadcast_project_storage_updated(project_storage:)
    end

    after { project_storage.update(project_folder_mode: :automatic) }

    it "broadcasts the project storage event" do
      expect(OpenProject::Notifications).to have_received(:send)
        .with(OpenProject::Events::PROJECT_STORAGE_UPDATED,
              project_folder_mode: :inactive,
              project_folder_mode_previously_was: :automatic,
              storage: project_storage.storage)
    end
  end

  describe ".automatic_folder_mode_broadcast?" do
    subject { described_class.automatic_folder_mode_broadcast?(broadcasted_payload) }

    context "when project_folder_mode is automatic" do
      let(:broadcasted_payload) { { project_folder_mode: "automatic" } }

      it { is_expected.to be(true) }
    end

    context "when project_folder_mode_previously_was is automatic" do
      let(:broadcasted_payload) { { project_folder_mode_previously_was: "automatic" } }

      it { is_expected.to be(true) }
    end

    context "when only one of project_folder_mode and project_folder_mode_previously_was is automatic" do
      let(:broadcasted_payload) { { project_folder_mode: "inactive", project_folder_mode_previously_was: "automatic" } }

      it { is_expected.to be(true) }
    end

    context "when both project_folder_mode and project_folder_mode_previously_was are not automatic" do
      let(:broadcasted_payload) { { project_folder_mode: "inactive", project_folder_mode_previously_was: "inactive" } }

      it { is_expected.to be(false) }
    end
  end
end
