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
require_relative "openid_connect_spec_helpers"

require Rails.root.join('db/migrate/20190106184413_remove_email_from_users.rb')
RSpec.describe RemoveEmailFromUsers do
  let(:migrations_paths) { ActiveRecord::Migrator.migrations_paths }
  let(:migrations) { ActiveRecord::MigrationContext.new(migrations_paths).migrations }
  let(:previous_version) { 20181204143322 }
  let(:current_version) { 20190106184413 }
  subject { ActiveRecord::Migrator.new(:up, migrations, current_version).migrate }
  around do |example|
    # Silence migrations output in specs report.
    ActiveRecord::Migration.suppress_messages do
      # Migrate back to the previous version
      ActiveRecord::Migrator.new(:down, migrations, ActiveRecord::SchemaMigration, previous_version).migrate

      # If other tests using User table ran before this one, Rails has
      # stored information about table's columns and we need to reset those
      # since the migration changed the database structure.
      User.reset_column_information
      example.run

      # Re-update column information after the migration has been executed
      # again in the example. This will make user attributes cache
      # ready for other tests.
      User.reset_column_information
    end
  end
  context 'when there are users with email' do
    let(:user_with_email) { create(:user, email: 'test@email.com') }
    it 'creates an Email associated with the same user' do
      expect { subject }
        .to change { Email.all.size }
              .from(0)
              .to(1)
      expect(Email.first.user).to eq user_with_email
      expect(Email.first.value).to eq 'test@email.com'
    end
  end
end
