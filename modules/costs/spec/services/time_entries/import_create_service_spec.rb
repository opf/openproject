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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe TimeEntries::ImportCreateService do
  subject(:service) { described_class.new(user:, contract_class: EmptyContract) }

  let(:user) { create(:user) }
  let(:work_package) { create(:work_package) }
  let(:params) { { user:, entity: work_package, hours: 1.5, spent_on: Date.new(2026, 10, 21) } }

  it "creates the time entry on the work package" do
    call = service.call(params)

    expect(call).to be_success
    expect(work_package.time_entries.reload.sole).to have_attributes(user:, hours: 1.5, project: work_package.project)
  end

  it "does not send a time entry created event" do
    allow(OpenProject::Notifications).to receive(:send).and_call_original

    service.call(params)

    expect(OpenProject::Notifications).not_to have_received(:send).with(OpenProject::Events::TIME_ENTRY_CREATED, any_args)
  end
end
