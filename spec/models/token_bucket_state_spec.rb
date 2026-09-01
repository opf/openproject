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

RSpec.describe TokenBucketState do
  describe ".with_instance" do
    # This is supposed to test that concurrent access to the singleton is blocked on DB level. However I wasn't able to
    # get this to work in the tests, as transactional fixtures are messing with the semantics of transactions in the
    # test context. Therefore, we're merely testing that `SELECT ... FOR UPDATE` is used.
    it "uses PostgreSQL row locking" do
      sql_queries = []

      callback = lambda do |_name, _start, _finish, _id, payload|
        sql_queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.with_instance(:email_limit_per_day) {} # trigger action
      end

      expect(sql_queries).to include(
        a_string_matching(/SELECT .* FROM "token_bucket_states" .* FOR UPDATE/i)
      )
    end

    it "passes the singleton instance into the block" do
      instance = described_class.with_instance(:email_limit_per_day) { it }

      expect(instance.identifier).to eq "email_limit_per_day"
    end
  end
end
