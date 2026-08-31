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

RSpec.describe Journals::CreateService, with_settings: { journal_aggregation_time_minutes: 0 } do # rubocop:disable RSpec/SpecFilePathFormat
  let(:work_package) { create(:work_package) }
  let(:instance) { described_class.new(work_package, User.system) }

  shared_examples "journalizing continues the predecessor's validity period" do
    it "creates a journal timestamped after the most recent one" do
      expect { instance.call(notes: "A note added afterwards") }
        .to change { work_package.journals.reload.count }.by(1)

      journal = work_package.journals.last
      predecessor.reload

      expect(journal.created_at).to be > predecessor.created_at
      expect(predecessor.validity_period).to eql(predecessor.created_at...journal.created_at)
      expect(journal.validity_period).to eql(journal.created_at...)
    end
  end

  # Rails timestamps the journable with the application clock while the service will fall back to the database clock
  # if only a note or a cause is journalized.
  # These two clocks can disagree, e.g. when the application and database run on separate machines.
  context "when the most recent journal is timestamped ahead of the database clock" do
    let!(:predecessor) do
      travel_to(1.minute.from_now) do
        work_package.update!(subject: "Journalized ahead of the database clock")
      end

      work_package.reload.journals.last
    end

    include_examples "journalizing continues the predecessor's validity period"

    it "keeps the journable's timestamp identical to the journal's" do
      instance.call(notes: "A note added afterwards")

      expect(work_package.reload.updated_at).to eql(work_package.journals.reload.last.created_at)
    end
  end

  # The journable instance can have a stale timestamp if the record has been touched directly in the database.
  context "when the journable has been touched in the database since it was loaded" do
    let!(:predecessor) { work_package.journals.last }

    before do
      WorkPackage.where(id: work_package.id).update_all(updated_at: 1.minute.from_now)
    end

    include_examples "journalizing continues the predecessor's validity period"

    it "keeps the journable's database timestamp identical to the journal's" do
      instance.call(notes: "A note added afterwards")

      expect(work_package.reload.updated_at).to eql(work_package.journals.reload.last.created_at)
    end
  end
end
