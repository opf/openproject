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

require_relative "../../spec_helper"

RSpec.describe Meeting, "changes broadcast via journal events" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:meeting) { create(:meeting) }

  let(:stream) { meeting.to_gid_param }
  let(:changed_broadcast) do
    have_broadcasted_to(stream)
      .with(a_string_including(%(action="dispatchEvent"), %(event-name="op-dispatched:meeting-changed")))
      .once
  end

  before do
    allow(OpenProject::LiveUpdates).to receive(:enabled?).and_return(live_updates)
  end

  context "with live updates enabled" do
    let(:live_updates) { true }

    it "signals a journaled change of the meeting" do
      expect { meeting.update!(title: "Renamed") }.to changed_broadcast
    end

    it "signals a journaled change of the agenda" do
      create(:meeting_agenda_item, meeting:)

      expect { meeting.touch_and_save_journals }.to changed_broadcast
    end

    it "does not signal a change that is not journaled" do
      expect { create(:meeting_section, meeting:) }.not_to have_broadcasted_to(stream)
    end

    it "does not signal while journal event callbacks are disabled" do
      expect { Journal::EventConfiguration.with(false) { meeting.update!(title: "Renamed") } }
        .not_to have_broadcasted_to(stream)
    end
  end

  context "with live updates disabled" do
    let(:live_updates) { false }

    it "does not broadcast" do
      expect { meeting.update!(title: "Renamed") }.not_to have_broadcasted_to(stream)
    end
  end
end
