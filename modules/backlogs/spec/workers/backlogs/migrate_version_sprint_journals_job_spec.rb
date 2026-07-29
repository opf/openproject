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

RSpec.describe Backlogs::MigrateVersionSprintJournalsJob, type: :model do
  shared_let(:project) { create(:project) }
  shared_let(:version_a) { create(:version, project:, name: "Version A") }
  shared_let(:version_b) { create(:version, project:, name: "Version B") }
  shared_let(:sprint_a) { create(:sprint, name: "Sprint A", project:) }
  shared_let(:sprint_b) { create(:sprint, name: "Sprint B", project:) }
  shared_let(:wp1) { create(:work_package, project:, version: version_a, sprint: sprint_a) }
  shared_let(:wp2) { create(:work_package, project:, version: version_b, sprint: sprint_b) }
  shared_let(:wp_no_version) { create(:work_package, project:, sprint: sprint_a) }

  subject(:perform) { job.perform }

  let(:job) { described_class.new }

  describe "#perform" do
    context "when there are work packages associated with a sprint and a version" do
      it "creates a journal entry for each work package authored by the system user" do
        perform
        expect(wp1.reload.last_journal.user).to eq(User.system)
        expect(wp2.reload.last_journal.user).to eq(User.system)
      end

      it "sets the cause type to system_update" do
        perform
        expect(wp1.reload.last_journal.cause_type).to eq("system_update")
        expect(wp2.reload.last_journal.cause_type).to eq("system_update")
      end

      it "sets the cause feature to sprint_migration" do
        perform
        expect(wp1.reload.last_journal.cause_feature).to eq("sprint_migration")
        expect(wp2.reload.last_journal.cause_feature).to eq("sprint_migration")
      end

      it "stores the originating version name in the cause" do
        perform
        expect(wp1.reload.last_journal.cause["version_name"]).to eq("Version A")
        expect(wp2.reload.last_journal.cause["version_name"]).to eq("Version B")
      end

      it "suppresses journal notifications" do
        allow(Journal::NotificationConfiguration).to receive(:with).and_call_original
        perform
        expect(Journal::NotificationConfiguration).to have_received(:with).with(false)
      end
    end

    context "when there is a work package associated with a sprint but no version" do
      it "does not create a system update journal entry" do
        perform
        expect(wp_no_version.reload.last_journal.cause_type).not_to eq("system_update")
        expect(wp_no_version.reload.last_journal.cause_feature).not_to eq("sprint_migration")
      end
    end

    context "when a work package has multiple target versions" do
      shared_let(:wp_multi) do
        create(:work_package, project:, version: version_b, sprint: sprint_a).tap do |wp|
          create(:work_package_version, work_package: wp, version: version_a, kind: :target)
        end
      end

      it "creates one journal entry naming the primary (lowest id) target version" do
        perform
        journals = wp_multi.reload.journals.select { it.cause_feature == "sprint_migration" }
        expect(journals.size).to eq(1)
        expect(journals.first.cause["version_name"]).to eq("Version A")
      end
    end

    context "when the work_package_versions table does not exist yet" do
      before do
        allow(job).to receive(:work_package_versions_available?).and_return(false)
      end

      it "journals via the legacy version_id column" do
        perform
        expect(wp1.reload.last_journal.cause["version_name"]).to eq("Version A")
        expect(wp2.reload.last_journal.cause["version_name"]).to eq("Version B")
      end

      it "does not create a system update journal entry for a work package without a version" do
        perform
        expect(wp_no_version.reload.last_journal.cause_feature).not_to eq("sprint_migration")
      end
    end
  end
end
