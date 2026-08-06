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

RSpec.describe WorkPackageTypes::CopyConfiguration::FormConfigurationService do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type) }
  let(:source) { create(:type) }

  subject(:service_call) { described_class.new(type:, user: admin).call(source:) }

  before do
    login_as(admin)
    RequestStore.clear!
  end

  describe "attribute groups" do
    before do
      source.attribute_groups = [
        ["custom group", %w[assignee responsible]],
        [:details, %w[priority], "Renamed details"]
      ]
      source.save!
      source.reload
    end

    it "copies the groups including custom names onto the type" do
      expect(service_call).to be_success

      groups = type.reload.attribute_groups
      expect(groups.map { |group| [group.key, group.attributes, group.display_name] })
        .to eq([
                 ["custom group", %w[assignee responsible], nil],
                 [:details, %w[priority], "Renamed details"]
               ])
    end
  end

  describe "embedded query groups" do
    let(:source_query) { build(:global_query, user_id: 0) }

    before do
      source.attribute_groups = [["Related work packages", [source_query]]]
      source.save!
      source.reload
    end

    it "copies the group with a fresh query instead of sharing the source's" do
      expect { service_call }.to change(Query, :count).by(1)

      copied_group = type.reload.attribute_groups.detect { |group| group.is_a?(Type::QueryGroup) }
      expect(copied_group.key).to eq("Related work packages")
      expect(copied_group.query.id).not_to eq(source_query.id)
    end

    it "leaves the source's query untouched" do
      expect(service_call).to be_success

      expect(Query.find_by(id: source_query.id)).to be_present
      expect(source.reload.attribute_groups.first.query).to eq(source_query)
    end
  end

  describe "cleaning the previous configuration" do
    let(:existing_query) { build(:global_query, user_id: 0) }
    let!(:existing_custom_field) { create(:work_package_custom_field, field_format: "string") }

    before do
      type.attribute_groups = [
        ["Old table", [existing_query]],
        ["old group", [existing_custom_field.attribute_name]]
      ]
      type.custom_field_ids = [existing_custom_field.id]
      type.save!
      type.reload

      source.attribute_groups = [["copied group", %w[assignee]]]
      source.save!
      source.reload
    end

    it "destroys the type's previous embedded queries" do
      expect(service_call).to be_success

      expect(Query.find_by(id: existing_query.id)).to be_nil
    end

    it "replaces the groups and deactivates custom fields the source does not use" do
      expect(service_call).to be_success

      type.reload
      expect(type.attribute_groups.map(&:key)).to eq(["copied group"])
      expect(type.custom_field_ids).to be_empty
    end
  end

  describe "custom fields" do
    let!(:source_custom_field) { create(:work_package_custom_field, field_format: "string") }

    before do
      source.attribute_groups = [["cf group", [source_custom_field.attribute_name]]]
      source.custom_field_ids = [source_custom_field.id]
      source.save!
      source.reload
    end

    it "activates the source's custom fields on the type" do
      expect(service_call).to be_success

      type.reload
      expect(type.attribute_groups.first.attributes).to eq([source_custom_field.attribute_name])
      expect(type.custom_field_ids).to eq([source_custom_field.id])
    end
  end

  describe "with a Linked source", with_flag: { type_variants: true } do
    let(:owner) { create(:type) }

    before do
      owner.attribute_groups = [["owner group", %w[assignee]]]
      owner.save!
      owner.reload

      source.link!(Type::ConfigurationLink::FORM_CONFIGURATION, source: owner)
    end

    it "copies the configuration the source effectively presents" do
      expect(service_call).to be_success

      expect(type.reload.attribute_groups.map(&:key)).to eq(["owner group"])
    end
  end

  # Switching to Independent copies from the type's own link source, so the copy has to freeze
  # what the type was presenting — not restore the elements its link chain excluded.
  describe "when the type's link excludes elements", with_flag: { type_variants: true } do
    let!(:kept_field) { create(:work_package_custom_field, field_format: "string") }
    let!(:excluded_field) { create(:work_package_custom_field, field_format: "string") }
    let!(:solo_field) { create(:work_package_custom_field, field_format: "string") }

    # The copy runs while the link is still in place — SwitchToIndependentModeService severs it
    # afterwards — and Type#attribute_groups resolves through a live link. Reading it directly
    # would therefore show the still-inherited view and hold whatever was actually persisted, so
    # these assertions sever the link first and look at the type's own stored groups.
    def own_groups
      type.configuration_links.destroy_all

      type.reload.attribute_groups.to_h { |group| [group.key, group.attributes] }
    end

    before do
      source.attribute_groups = [
        ["numbers", [kept_field.attribute_name, excluded_field.attribute_name]],
        ["solo", [solo_field.attribute_name]],
        ["people", %w[assignee]]
      ]
      source.custom_field_ids = [kept_field.id, excluded_field.id, solo_field.id]
      source.save!
      source.reload

      create(:type_configuration_link, type:, source:,
                                       aspect: Type::ConfigurationLink::FORM_CONFIGURATION,
                                       excluded_elements: [excluded_field.attribute_name,
                                                           solo_field.attribute_name])
    end

    it "copies the narrowed groups and drops the emptied one" do
      expect(service_call).to be_success

      expect(own_groups.keys).to contain_exactly("numbers", "people")
      expect(own_groups["numbers"]).to eq([kept_field.attribute_name])
    end

    it "activates only the custom fields that survived the exclusions" do
      expect(service_call).to be_success

      expect(type.reload.custom_field_ids).to contain_exactly(kept_field.id)
    end

    it "leaves the source's own configuration complete" do
      service_call

      expect(source.reload.attribute_groups.map(&:key))
        .to contain_exactly("numbers", "solo", "people")
      expect(source.custom_field_ids)
        .to contain_exactly(kept_field.id, excluded_field.id, solo_field.id)
    end

    context "with exclusions accumulated over a chain" do
      let(:owner) { create(:type) }

      before do
        # Rebuild as owner <- source <- type, each link dropping a little more.
        type.configuration_links.destroy_all
        owner.attribute_groups = source.attribute_groups.map { |g| [g.key, g.attributes] }
        owner.custom_field_ids = [kept_field.id, excluded_field.id, solo_field.id]
        owner.save!

        source.update!(attribute_groups: [])
        create(:type_configuration_link, type: source, source: owner,
                                         aspect: Type::ConfigurationLink::FORM_CONFIGURATION,
                                         excluded_elements: [excluded_field.attribute_name])
        create(:type_configuration_link, type:, source:,
                                         aspect: Type::ConfigurationLink::FORM_CONFIGURATION,
                                         excluded_elements: [solo_field.attribute_name])
      end

      it "applies every link's exclusions, not just the nearest one" do
        expect(service_call).to be_success

        expect(type.reload.custom_field_ids).to contain_exactly(kept_field.id)
        expect(own_groups.keys).to contain_exactly("numbers", "people")
        expect(own_groups["numbers"]).to eq([kept_field.attribute_name])
      end
    end

    context "with an excluded query group" do
      let!(:embedded_query) { create(:query, user: admin, name: "Embedded") }

      before do
        source.attribute_groups = [
          ["numbers", [kept_field.attribute_name]],
          ["related", [embedded_query]]
        ]
        source.save!
        source.reload

        type.configuration_links
            .find_by(aspect: Type::ConfigurationLink::FORM_CONFIGURATION)
            .update!(excluded_elements: ["query_#{embedded_query.id}"])
      end

      it "does not copy the excluded section" do
        expect(service_call).to be_success

        expect(own_groups.keys).to contain_exactly("numbers")
      end

      # The copy rebuilds query groups as fresh Query records, so an excluded section must be
      # dropped before that happens rather than leaving an orphan query behind.
      it "does not rebuild a query for it" do
        expect { service_call }.not_to change(Query, :count)
      end
    end
  end

  # "Copy from type" on the form configuration tab passes an arbitrary source, whose own
  # exclusions are what the user saw when picking it.
  describe "copying from an unrelated Linked type", with_flag: { type_variants: true } do
    let(:owner) { create(:type) }
    let!(:kept_field) { create(:work_package_custom_field, field_format: "string") }
    let!(:excluded_field) { create(:work_package_custom_field, field_format: "string") }

    before do
      owner.attribute_groups = [["numbers", [kept_field.attribute_name, excluded_field.attribute_name]]]
      owner.custom_field_ids = [kept_field.id, excluded_field.id]
      owner.save!
      owner.reload

      create(:type_configuration_link, type: source, source: owner,
                                       aspect: Type::ConfigurationLink::FORM_CONFIGURATION,
                                       excluded_elements: [excluded_field.attribute_name])
    end

    # `type` is Independent here, so its own groups are what the reader returns already.
    it "copies what that type presents, not the owner's full configuration" do
      expect(service_call).to be_success

      expect(type.reload.attribute_groups.first.attributes).to eq([kept_field.attribute_name])
      expect(type.custom_field_ids).to contain_exactly(kept_field.id)
    end
  end

  describe "invalid sources" do
    before do
      type.attribute_groups = [["existing group", %w[assignee]]]
      type.save!
      type.reload
    end

    it "fails when the source is the type itself and keeps the configuration" do
      result = described_class.new(type:, user: admin).call(source: type)

      expect(result).to be_failure
      expect(type.reload.attribute_groups.map(&:key)).to eq(["existing group"])
    end

    it "fails without a source" do
      result = described_class.new(type:, user: admin).call(source: nil)

      expect(result).to be_failure
    end
  end
end
