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

RSpec.describe Sessions::ClearOldSessionsService do
  shared_let(:user) { create(:user) }

  def create_session(updated_at:, user_id: nil)
    ActiveRecord::SessionStore::Session.create!(session_id: SecureRandom.hex, data: {}, user_id:, updated_at:)
  end

  let!(:recent_anonymous) { create_session(updated_at: 1.hour.ago) }
  let!(:stale_anonymous) { create_session(updated_at: 2.days.ago) }
  let!(:recent_user) { create_session(updated_at: 2.days.ago, user_id: user.id) }
  let!(:stale_user) { create_session(updated_at: 31.days.ago, user_id: user.id) }

  it "removes anonymous sessions after one day and user sessions after 30 days" do
    described_class.call!

    expect(ActiveRecord::SessionStore::Session.all)
      .to contain_exactly(recent_anonymous, recent_user)
  end

  it "respects custom retention periods" do
    described_class.call!(days_ago: 40, anonymous_days_ago: 3)

    expect(ActiveRecord::SessionStore::Session.all)
      .to contain_exactly(recent_anonymous, stale_anonymous, recent_user, stale_user)
  end
end
