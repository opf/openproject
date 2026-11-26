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

RSpec.describe OpenProject::Database do
  before do
    described_class.instance_variable_set(:@version, nil)
  end

  after do
    described_class.instance_variable_set(:@version, nil)
  end

  it "returns the correct identifier" do
    allow(OpenProject::Database).to receive(:adapter_name).and_return "PostgresQL"

    expect(OpenProject::Database.name).to equal(:postgresql)
  end

  it "is able to use the helper methods" do
    allow(OpenProject::Database).to receive(:adapter_name).and_return "PostgresQL"

    expect(OpenProject::Database.postgresql?).to equal(true)
  end

  it "returns a version string for PostgreSQL" do
    allow(OpenProject::Database).to receive(:adapter_name).and_return "PostgreSQL"
    raw_version = "PostgreSQL 8.3.11 on x86_64-pc-linux-gnu, compiled by GCC gcc-4.3.real (Debian 4.3.2-1.1) 4.3.2"
    allow(ActiveRecord::Base.connection).to receive(:select_value).and_return raw_version

    expect(OpenProject::Database.version).to eq("8.3.11")
    expect(OpenProject::Database.version(true)).to eq(raw_version)
  end

  describe ".check_all_pending_migrations!" do
    let(:migration_context) { ActiveRecord::Base.connection_pool.migration_context }

    before do
      allow(ActiveRecord::Base.connection_pool).to receive(:migration_context).and_return(migration_context)
    end

    it "does not raise when all migrations are applied" do
      expect { described_class.check_all_pending_migrations! }.not_to raise_error
    end

    it "raises listing the pending migrations" do
      pending_migration = migration_context.migrations.last
      allow(migration_context)
        .to receive(:get_all_versions)
        .and_return(migration_context.migrations.map(&:version) - [pending_migration.version])

      expect { described_class.check_all_pending_migrations! }
        .to raise_error(ActiveRecord::PendingMigrationError, /#{Regexp.escape(pending_migration.basename)}/)
    end

    context "when the database schema has not been loaded yet" do
      before do
        allow(migration_context.schema_migration).to receive(:table_exists?).and_return(false)
      end

      it "raises without creating the schema_migrations or ar_internal_metadata tables", :aggregate_failures do
        expect(migration_context.schema_migration).not_to receive(:create_table)
        expect(migration_context.internal_metadata).not_to receive(:create_table)

        expect { described_class.check_all_pending_migrations! }
          .to raise_error(ActiveRecord::PendingMigrationError)
      end
    end
  end
end
