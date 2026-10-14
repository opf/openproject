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
require Rails.root.join("db/migrate/20261012181352_create_live_updates_subscriptions")

RSpec.describe CreateLiveUpdatesSubscriptions, type: :model do
  let(:connection) { ActiveRecord::Base.connection }

  def migrate(direction)
    ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }
  end

  it "drops the table on the way down and creates it on the way up" do
    migrate(:down)
    expect(connection.table_exists?(:live_updates_subscriptions)).to be(false)

    migrate(:up)
    expect(connection.table_exists?(:live_updates_subscriptions)).to be(true)
    expect(connection.columns(:live_updates_subscriptions).map(&:name))
      .to contain_exactly("id", "user_id", "stream_name", "session_id", "created_at", "updated_at")
  end
end
