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
require Rails.root.join("db/migrate/migration_utils/utils")

RSpec.describe Migration::Utils do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:migration) do
    Class.new(ActiveRecord::Migration[8.0]) { include Migration::Utils }.new
  end

  let(:table) { :tmp_migration_utils_indexes }
  let(:columns) { %w[foo_id bar_id] }

  around do |example|
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection.create_table(table, id: false, force: true) do |t|
        t.bigint :foo_id
        t.bigint :bar_id
      end
      example.run
      ActiveRecord::Base.connection.drop_table(table, if_exists: true)
    end
  end

  def index_names
    migration.indexes(table).map(&:name)
  end

  describe "#remove_index_on" do
    it "removes an index by canonical name" do
      migration.add_index table, columns, name: "my_composite_index"

      migration.remove_index_on table, "my_composite_index", columns

      expect(index_names).not_to include("my_composite_index")
    end

    it "removes a pgloader-prefixed index by canonical name" do
      migration.add_index table, columns, name: "idx_4408199_my_composite_index"

      migration.remove_index_on table, "my_composite_index", columns

      expect(index_names).not_to include("idx_4408199_my_composite_index")
    end

    it "falls back to columns when the name does not match" do
      migration.add_index table, columns, name: "index_tmp_migration_utils_indexes_on_foo_id_and_bar_id"

      migration.remove_index_on table, "my_composite_index", columns

      expect(index_names).to be_empty
    end

    it "does nothing when no matching index exists" do
      expect { migration.remove_index_on table, "missing_index", columns }.not_to raise_error
    end
  end

  describe "#rename_index_on" do
    it "renames a pgloader-prefixed index" do
      migration.add_index table, columns, name: "idx_4408199_old_index"

      migration.rename_index_on table, "old_index", "new_index", columns

      expect(index_names).to include("new_index")
      expect(index_names).not_to include("idx_4408199_old_index")
    end
  end
end
