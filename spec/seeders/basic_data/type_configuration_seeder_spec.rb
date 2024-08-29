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

RSpec.describe BasicData::TypeConfigurationSeeder do
  include_context "with basic seed data", edition: "bim"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }
  let(:phase_type) { seed_data.find_reference(:default_type_phase).reload }
  let(:data_hash) { {} }

  context "without any form_configuration for the given type" do
    it "does not change attribute_groups" do
      attribute_groups_before = phase_type.attribute_groups.dup
      seeder.seed!
      attribute_groups_now = phase_type.attribute_groups
      expect(attribute_groups_now).to eq(attribute_groups_before)
    end
  end

  context "with a form_configuration entry in type_configuration in seed data" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        type_configuration:
        - type: :default_type_phase
          form_configuration:
            - group_name: "Children"
              query: :query__children
            - group_name: "Bugs of the week"
              query: :query__bugs_of_the_week
      SEEDING_DATA_YAML
    end
    let(:query) { create(:query, name: "Children") }
    let(:bugs_of_the_week_query) { create(:query, name: "Bugs of the week") }

    before do
      seed_data.store_reference(:query__children, query)
      seed_data.store_reference(:query__bugs_of_the_week, bugs_of_the_week_query)
    end

    it "adds the given query groups in the form configuration of the type" do
      attribute_groups_before = phase_type.attribute_groups.dup
      seeder.seed!
      attribute_groups_now = phase_type.attribute_groups
      expect(attribute_groups_now).not_to eq(attribute_groups_before)
      expect(attribute_groups_now)
        .to include(an_instance_of(Type::QueryGroup).and(having_attributes(attributes: query)))
      expect(attribute_groups_now)
        .to include(an_instance_of(Type::QueryGroup).and(having_attributes(attributes: bugs_of_the_week_query)))
    end
  end
end
