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

# Commits every write for real so threads, locks and workers see each
# other's rows. Use only for genuine concurrency specs: all tables are
# truncated afterwards, so stop workers first and expect no fixtures.
RSpec.shared_context "with real database commits" do
  self.use_transactional_tests = false

  around do |example|
    if ActiveRecord::Base.connection_pool.lease_connection.transaction_open?
      raise "Enclosing transaction prevents genuine concurrency"
    end

    settings_rows = Setting.pluck(:name, :value).map { |name, value| { name:, value: } }

    begin
      example.run
    ensure
      ActiveRecord::Tasks::DatabaseTasks.truncate_all("test")
      Setting.insert_all!(settings_rows) if settings_rows.any?
      Setting.clear_cache
      Rails.cache.clear
      RequestStore.clear!
    end
  end
end
