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
require_module_spec_helper

RSpec.describe OpenProject::Llm::Pgvector do
  def forget_memoized_availability
    described_class.remove_instance_variable(:@available) if described_class.instance_variable_defined?(:@available)
  end

  before { forget_memoized_availability }
  after { forget_memoized_availability }

  describe ".register_active_record_type" do
    let(:connection) { ActiveRecord::Base.connection }

    it "resolves halfvec in the connection's type map instead of the unknown-OID fallback" do
      oid = connection.select_value("SELECT 'halfvec'::regtype::oid")
      type = connection.send(:get_oid_type, oid, nil, "embedding")

      expect(type).to be_an(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::SpecializedString)
    end
  end

  describe ".available?" do
    it "is true when the extension is installed and its migrations have run" do
      expect(described_class.available?).to be(true)
    end

    it "is false when the extension is not installed" do
      allow(described_class).to receive(:extension_installed?).and_return(false)

      expect(described_class.available?).to be(false)
    end

    it "is false while its migrations are pending" do
      allow(described_class).to receive(:migrations_applied?).and_return(false)

      expect(described_class.available?).to be(false)
    end
  end

  describe ".enable" do
    let(:connection) { ActiveRecord::Base.connection }

    def raise_from_postgres(pg_error)
      raise pg_error, "boom"
    rescue PG::Error
      raise ActiveRecord::StatementInvalid, "boom"
    end

    it "succeeds when the extension is already installed" do
      expect(described_class.enable).to be_nil
    end

    it "reports if pgvector is unavailable" do
      allow(described_class).to receive(:extension_available?).and_return(false)

      expect(described_class.enable).to have_attributes(reason: :unavailable)
    end

    it "reports a database user that may not create the extension" do
      allow(connection).to receive(:execute).and_call_original
      allow(connection).to receive(:execute).with(/CREATE EXTENSION/) { raise_from_postgres(PG::InsufficientPrivilege) }

      expect(described_class.enable).to have_attributes(reason: :insufficient_privilege, detail: "boom")
    end

    it "reports any other failure" do
      allow(connection).to receive(:execute).and_call_original
      allow(connection).to receive(:execute).with(/CREATE EXTENSION/) { raise_from_postgres(PG::InternalError) }

      expect(described_class.enable).to have_attributes(reason: :failed)
    end
  end

  describe ".include_migrations_path!" do
    it "adds the pgvector migrations to the migration paths only once when called multiple times" do
      2.times { described_class.include_migrations_path! }

      expect(ActiveRecord::Migrator.migrations_paths.count(described_class.migrations_path)).to eq(1)
    end
  end

  describe ".warning" do
    it "tells how to grant the permission when it is missing" do
      failure = described_class::Failure.new(reason: :insufficient_privilege, detail: nil)

      expect(described_class.warning(failure)).to include("The database user is not allowed to create the pgvector extension")
    end
  end

  describe "semantic search feature", with_flag: { semantic_search: true } do
    let(:feature) { OpenProject::Llm::Features[:semantic_search] }

    it "is available with pgvector" do
      expect(feature).to be_available
    end

    it "is unavailable without pgvector" do
      allow(described_class).to receive(:available?).and_return(false)

      expect(feature).not_to be_available
    end
  end
end
