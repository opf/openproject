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

require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s
require Rails.root.join("db/migrate/tables/base").to_s
Dir[File.join(__dir__, "tables/*.rb")].each { |file| require file }

class AggregatedTwoFactorAuthenticationMigrations < SquashedMigration
  squashed_migrations *%w[
    20120214103300_aggregated_mobile_otp_migrations
    20130214130336_add_default_otp_channel_to_user
    20160331190036_change_default_channel
    20171023190036_model_reorganization
    20230627133534_add_webauthn_fields_to_two_factor_table
  ].freeze

  tables Tables::TwoFactorAuthenticationDevices

  modifications do
    add_column :users, :webauthn_id, :string, null: true
  end
end
