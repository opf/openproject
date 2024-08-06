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

RSpec.describe DemoData::GlobalQuerySeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  before do
    AdminUserSeeder.new(seed_data).seed!
  end

  context "with a global_queries defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        global_queries:
        - name: "Children"
          reference: :global_query__children
          parent: '{id}'
          timeline: false
          sort_by: id
          hidden: true
          public: false
          columns:
            - type
            - id
            - subject
            - status
            - assigned_to
            - priority
            - project
      SEEDING_DATA_YAML
    end

    it "creates a global query" do
      expect { seeder.seed! }.to change { Query.global.count }.by(1)
    end

    it "references the query in the seed data" do
      seeder.seed!
      created_query = Query.global.first
      expect(seed_data.find_reference(:global_query__children)).to eq(created_query)
    end
  end
end
