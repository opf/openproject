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

RSpec.describe ApplicationCable::Connection do
  shared_let(:user) { create(:user) }

  it "identifies the user of the session" do
    connect session: { user_id: user.id }

    expect(connection.current_user).to eq(user)
  end

  it "rejects a connection without a logged in user" do
    expect { connect }.to have_rejected_connection
  end

  it "rejects a locked user" do
    locked_user = create(:locked_user)

    expect { connect session: { user_id: locked_user.id } }.to have_rejected_connection
  end

  context "with a session TTL", with_settings: { session_ttl_enabled?: true, session_ttl: "120" } do
    it "identifies the user of a session active within the TTL" do
      connect session: { user_id: user.id, updated_at: 10.minutes.ago }

      expect(connection.current_user).to eq(user)
    end

    it "rejects a session that exceeded the TTL" do
      expect { connect session: { user_id: user.id, updated_at: 3.hours.ago } }.to have_rejected_connection
    end
  end
end
