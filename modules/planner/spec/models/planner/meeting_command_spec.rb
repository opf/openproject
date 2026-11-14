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

RSpec.describe Planner::MeetingCommand do
  let(:project) { create(:project) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  let(:sakura) do
    create(:user, login: "sakura", firstname: "Sakura", lastname: "Haruno",
                  member_with_permissions: { project => %i[view_work_packages] })
  end
  let!(:stranger) { create(:user, login: "stranger") }
  let(:subject_text) { "Set up a /meeting with @#{sakura.login} and @stranger about wiki permissions" }
  let(:work_package) { build(:work_package, subject: subject_text) }

  subject(:command) { described_class.for(work_package, user) }

  it "takes the topic as title and the visible mentioned people as participants" do
    expect(command.title).to eq("Wiki permissions")
    expect(command.participants).to contain_exactly(sakura)
  end

  context "without a topic" do
    let(:subject_text) { "/meeting with @#{sakura.login}" }

    it "names the meeting after the participants" do
      expect(command.title).to eq("Meeting with Sakura Haruno")
    end
  end

  context "without the command" do
    let(:subject_text) { "Reply to @#{sakura.login} about the meeting" }

    it "is not a meeting command" do
      expect(command).to be_nil
    end
  end
end
