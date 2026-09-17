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

RSpec.describe WorkPackages::Import::CSV::ScheduleService do
  subject(:service) { described_class.new(user:, project:) }

  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[add_work_packages import_work_packages]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }
  shared_let(:other_user) { create(:user) }

  let(:file) do
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/csv_import/work_packages.csv"), "text/csv")
  end

  def uncontainered(author: user, container: nil)
    create(:attachment, container:, author:)
  end

  describe "an uploaded file" do
    it "stores it uncontainered and enqueues the job" do
      expect { service.call(file:) }
        .to change(Attachment.where(container: nil), :count).by(1)
        .and have_enqueued_job(WorkPackages::Import::CSV::CsvImportJob)
    end

    it "returns the job id the page polls" do
      result = service.call(file:)

      expect(result).to be_success
      expect(result.result).to be_present
    end

    it "does not apply the attachment allowlist, since the permission is the gate" do
      allow(Setting).to receive(:attachment_whitelist).and_return(["application/pdf"])

      expect(service.call(file:)).to be_success
    end

    it "passes the dry run through" do
      service.call(file:, dry_run: false)

      expect(WorkPackages::Import::CSV::CsvImportJob)
        .to have_been_enqueued.with(hash_including(dry_run: false))
    end
  end

  describe "reusing a checked file" do
    it "accepts the user's own uncontainered attachment" do
      attachment = uncontainered

      expect { service.call(attachment_id: attachment.id, dry_run: false) }
        .to have_enqueued_job(WorkPackages::Import::CSV::CsvImportJob)
        .with(hash_including(attachment_id: attachment.id))
    end

    it "refuses one belonging to somebody else" do
      attachment = uncontainered(author: other_user)

      expect(service.call(attachment_id: attachment.id)).to be_failure
      expect(WorkPackages::Import::CSV::CsvImportJob).not_to have_been_enqueued
    end

    it "refuses one that has since been claimed into a container" do
      attachment = uncontainered(container: create(:work_package))

      expect(service.call(attachment_id: attachment.id)).to be_failure
    end

    it "refuses one the sweep has already removed" do
      result = service.call(attachment_id: 0)

      expect(result).to be_failure
      expect(result.message).to eq("This file is no longer available. Upload it again.")
    end
  end
end
