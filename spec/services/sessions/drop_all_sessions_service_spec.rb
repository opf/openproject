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

RSpec.describe Sessions::DropAllSessionsService do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let!(:session) { create(:user_session, user: admin) }
  let!(:other_users_session) { create(:user_session, user: create(:user)) }
  let!(:elevation) { create(:admin_elevation_session, user: admin, project:, session_id: session.session_id) }

  subject { described_class.call!(admin) }

  it "drops all sessions of the user", :aggregate_failures do
    subject

    expect(Sessions::UserSession.for_user(admin)).to be_empty
    expect(Sessions::UserSession.find_by(session_id: other_users_session.session_id)).to be_present
  end

  it "ends the elevations of the user" do
    freeze_time do
      subject

      expect(elevation.reload.ended_at).to eq(Time.current)
    end
  end
end
