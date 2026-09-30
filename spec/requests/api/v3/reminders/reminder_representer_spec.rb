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

RSpec.describe API::V3::Reminders::ReminderRepresenter do
  let(:user) { build_stubbed(:user) }
  let(:remindable) { build_stubbed(:work_package) }
  let(:reminder) { build_stubbed(:reminder, remindable:, creator: user) }
  let(:representer) { described_class.new(reminder, current_user: user) }
  let(:parsed) { representer.to_hash }

  it "renders the id" do
    expect(parsed["id"]).to eq reminder.id
  end

  it "renders the remindAt" do
    expect(parsed["remindAt"]).to eq reminder.remind_at.iso8601(3)
  end

  it "renders the note" do
    expect(parsed["note"]).to eq reminder.note
  end

  it "renders the _type" do
    expect(parsed["_type"]).to eq "Reminder"
  end

  it "renders the self link" do
    expect(parsed["_links"]).to have_key("self")
    expect(parsed["_links"]["self"]["href"]).to include("/api/v3/reminders/#{reminder.id}")
  end

  it "renders the creator link" do
    expect(parsed["_links"]).to have_key("creator")
    expect(parsed["_links"]["creator"]["href"]).to include("/api/v3/users/#{user.id}")
  end

  it "renders the remindable link" do
    expect(parsed["_links"]).to have_key("remindable")
    expect(parsed["_links"]["remindable"]["href"]).to include("/api/v3/work_packages/#{remindable.id}")
  end
end
