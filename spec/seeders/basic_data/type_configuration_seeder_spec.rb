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
  let(:phase_variant) { seed_data.find_reference(:default_type_summary_task).reload.default_variant }
  let(:data_hash) { {} }

  context "without any form_configuration for the given type" do
    it "does not change attribute_groups" do
      attribute_groups_before = phase_variant.attribute_groups.dup
      seeder.seed!
      attribute_groups_now = phase_variant.attribute_groups
      expect(attribute_groups_now).to eq(attribute_groups_before)
    end
  end

  context "with a form_configuration referencing a query that is not registered" do
    # Happens when re-seeding an installation whose global queries still exist: the
    # GlobalQuerySeeder is then skipped and their references are not registered again.
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        type_configuration:
        - type: :default_type_summary_task
          form_configuration:
            - group_name: "Children"
              query: :query__not_registered
      SEEDING_DATA_YAML
    end

    it "skips the entry without raising and leaves the form configuration untouched" do
      attribute_groups_before = phase_variant.attribute_groups.dup
      expect { seeder.seed! }.not_to raise_error
      expect(phase_variant.attribute_groups).to eq(attribute_groups_before)
    end
  end

  context "with a form_configuration entry in type_configuration in seed data" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        type_configuration:
        - type: :default_type_summary_task
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
      attribute_groups_before = phase_variant.attribute_groups.dup
      seeder.seed!
      attribute_groups_now = phase_variant.reload.attribute_groups
      expect(attribute_groups_now).not_to eq(attribute_groups_before)
      expect(attribute_groups_now)
        .to include(an_instance_of(Type::QueryGroup).and(having_attributes(attributes: query)))
      expect(attribute_groups_now)
        .to include(an_instance_of(Type::QueryGroup).and(having_attributes(attributes: bugs_of_the_week_query)))
    end

    it "does not merge the default form configuration by default" do
      seeder.seed!
      expect(phase_variant.reload.attribute_groups).to all(be_a(Type::QueryGroup))
      expect(phase_variant.default_attribute_groups).to be_present # sanity check: there is something to merge
    end

    context "with merge_form_configuration enabled" do
      let(:data_hash) do
        YAML.load <<~SEEDING_DATA_YAML
          type_configuration:
          - type: :default_type_summary_task
            merge_form_configuration: true
            form_configuration:
              - group_name: "Children"
                query: :query__children
        SEEDING_DATA_YAML
      end

      it "appends the type's default form configuration to the seeded query groups" do
        default_group_keys = phase_variant.default_attribute_groups.map(&:first)
        seeder.seed!
        attribute_groups_now = phase_variant.reload.attribute_groups

        expect(attribute_groups_now.first)
          .to be_a(Type::QueryGroup).and(having_attributes(attributes: query))
        expect(attribute_groups_now.map(&:key)).to include("Children", *default_group_keys)
      end
    end
  end

  context "with a form_configuration entry listing plain attributes" do
    context "with an explicit group_name" do
      let(:data_hash) do
        YAML.load <<~SEEDING_DATA_YAML
          type_configuration:
          - type: :default_type_summary_task
            form_configuration:
              - group_name: "Versions"
                attributes:
                  - observed_in_versions
        SEEDING_DATA_YAML
      end

      it "adds an attribute group with the given title and attributes" do
        seeder.seed!
        attribute_groups_now = phase_variant.reload.attribute_groups

        expect(attribute_groups_now)
          .to include(an_instance_of(Type::AttributeGroup)
            .and(having_attributes(key: "Versions", attributes: ["observed_in_versions"])))
      end

      context "with merge_form_configuration enabled" do
        let(:data_hash) do
          YAML.load <<~SEEDING_DATA_YAML
            type_configuration:
            - type: :default_type_summary_task
              merge_form_configuration: true
              form_configuration:
                - group_name: "Versions"
                  attributes:
                    - observed_in_versions
          SEEDING_DATA_YAML
        end

        it "keeps the seeded attribute group alongside the type's default form configuration" do
          default_group_keys = phase_variant.default_attribute_groups.map(&:first)
          seeder.seed!
          attribute_groups_now = phase_variant.reload.attribute_groups

          expect(attribute_groups_now.map(&:key)).to include("Versions", *default_group_keys)
        end
      end
    end

    context "with a group_name matching one of the type's default groups" do
      let(:data_hash) do
        YAML.load <<~SEEDING_DATA_YAML
          type_configuration:
          - type: :default_type_summary_task
            merge_form_configuration: true
            form_configuration:
              - group_name: :details
                attributes:
                  - observed_in_versions
        SEEDING_DATA_YAML
      end

      it "merges the seeded attributes into that default group instead of creating a separate one" do
        default_details_members = phase_variant.default_attribute_groups.find { |key, _| key == :details }.last
        seeder.seed!
        attribute_groups_now = phase_variant.reload.attribute_groups

        details_groups = attribute_groups_now.select { |group| group.key == :details }
        expect(details_groups.size).to eq(1)
        expect(details_groups.first.attributes).to eq(default_details_members + ["observed_in_versions"])
      end
    end
  end
end
