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

RSpec.describe Activities::TimeEntryActivityProvider do
  let(:event_scope) { "time_entries" }
  let(:user) { create(:admin) }
  let(:work_package) do
    User.execute_as(user) do
      create(:work_package, project:)
    end
  end

  let(:events) do
    described_class
      .find_events(event_scope, user, Time.zone.yesterday.to_datetime, Time.zone.tomorrow.to_datetime, {})
  end

  before do
    User.execute_as(user) do
      create(:time_entry, entity: work_package, project:, user:)
    end
  end

  describe ".find_events" do
    context "when classic IDs are enabled", with_settings: { work_packages_identifier: "classic" } do
      let(:project) { create(:project) }

      it "uses the numeric identifier in the event title" do
        expect(events[0].event_title).to include("##{work_package.id}")
      end
    end

    context "when semantic IDs are enabled", with_settings: { work_packages_identifier: "semantic" } do
      let(:project) { create(:project, :semantic) }

      it "uses the semantic identifier in the event title" do
        semantic_id = work_package.reload.identifier

        expect(events[0].event_title).to include(semantic_id)
        expect(events[0].event_title).not_to include("##{work_package.id}")
      end
    end
  end
end
