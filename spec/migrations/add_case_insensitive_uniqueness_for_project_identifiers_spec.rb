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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require Rails.root.join("db/migrate/20260319120000_add_case_insensitive_uniqueness_for_project_identifiers")

RSpec.describe AddCaseInsensitiveUniquenessForProjectIdentifiers, type: :model do
  context "when the projects table is visible in a second schema on the search path" do
    let(:connection) { ActiveRecord::Base.connection }
    let(:shadow_schema) { "shadow_op_20108" }

    around do |example|
      original_search_path = connection.schema_search_path
      connection.execute("CREATE SCHEMA #{shadow_schema}")
      connection.execute("CREATE TABLE #{shadow_schema}.projects (LIKE public.projects)")
      connection.schema_search_path = "#{shadow_schema}, public"
      example.run
    ensure
      connection.schema_search_path = original_search_path
      connection.execute("DROP SCHEMA IF EXISTS #{shadow_schema} CASCADE")
    end

    it "stops before touching indexes and names both schemas" do
      expect { ActiveRecord::Migration.suppress_messages { described_class.new.up } }
        .to raise_error(StandardError, /"projects" table exists in more than one schema.*#{shadow_schema}, public\./)
    end
  end
end
