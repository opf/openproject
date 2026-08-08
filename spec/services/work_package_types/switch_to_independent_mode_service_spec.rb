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

RSpec.describe WorkPackageTypes::SwitchToIndependentModeService do
  let(:user) { create(:admin) }
  let(:type) { create(:type) }

  subject(:service) { described_class.new(type:, aspect:, user:) }

  describe "#call" do
    context "with the copy mode" do
      let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

      it "copies the linked source's configuration and severs the link" do
        source = create(:type)
        source.pdf_export_templates.disable_all
        source.save!
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.export_templates_disabled).to eq(source.export_templates_disabled)
      end
    end

    context "with the default mode (form configuration)" do
      let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

      it "resets to the administrator default groups and severs the link" do
        source = create(:type)
        source.attribute_groups = [["custom group", %w[assignee]]]
        source.save!
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::DEFAULT)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.attribute_groups.map(&:key)).to eq(Type.new.attribute_groups.map(&:key))
      end
    end

    # Going Independent freezes what the type was presenting, not what its source owns: an
    # excluded attribute was not on its form and must not reappear as an own group member.
    context "with the copy mode and exclusions (form configuration)", with_flag: { type_variants: true } do
      let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }
      let(:owner) do
        create(:type).tap do |owner_type|
          owner_type.attribute_groups = [["Numbers", [kept_field.attribute_name, excluded_field.attribute_name]],
                                         ["People", %w[assignee]]]
          owner_type.custom_field_ids = [kept_field.id, excluded_field.id]
          owner_type.save!
        end
      end

      shared_let(:kept_field) { create(:issue_custom_field, :integer, name: "Kept", is_for_all: true) }
      shared_let(:excluded_field) { create(:issue_custom_field, :integer, name: "Dropped", is_for_all: true) }

      def own_groups
        type.reload.read_attribute(:attribute_groups).to_h { |key, members| [key.to_s, members] }
      end

      it "leaves out what the type's own link excluded", :aggregate_failures do
        create(:type_configuration_link, type:, source: owner, aspect:,
                                         excluded_elements: [excluded_field.attribute_name, "assignee"])

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(own_groups.keys).to contain_exactly("Numbers")
        expect(own_groups["Numbers"]).to eq([kept_field.attribute_name])
        expect(type.custom_field_ids).to contain_exactly(kept_field.id)
      end

      it "leaves out what an ancestor's link excluded, which the type could not see either" do
        middle = create(:type)
        create(:type_configuration_link, type: middle, source: owner, aspect:,
                                         excluded_elements: [excluded_field.attribute_name])
        create(:type_configuration_link, type:, source: middle, aspect:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).to be_success
        expect(own_groups["Numbers"]).to eq([kept_field.attribute_name])
      end
    end

    context "with the empty mode (patterns)" do
      let(:aspect) { Type::ConfigurationLink::DEFAULTS }

      it "clears the configuration and severs the link" do
        source = create(:type, patterns: { subject: { blueprint: "X {{id}}", enabled: true } })
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::EMPTY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.patterns.to_h).to be_empty
      end
    end

    context "with the empty mode (workflows)", with_flag: { type_variants: true } do
      let(:aspect) { Type::ConfigurationLink::WORKFLOWS }

      it "removes all transitions and severs the link" do
        source = create(:type)
        source.own_workflows.create!(role: create(:project_role),
                                     old_status: create(:status), new_status: create(:status),
                                     author: false, assignee: false)
        type.link!(aspect, source:)

        # The type owns no transitions but sees the source's through the link
        expect(type.own_workflows).to be_empty
        expect(type.workflows).not_to be_empty

        result = service.call(mode: WorkPackageTypes::IndependentMode::EMPTY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.own_workflows).to be_empty
        expect(type.workflows).to be_empty
      end
    end

    context "with the copy mode (project attributes)" do
      let(:aspect) { Type::ConfigurationLink::PROJECT_ATTRIBUTES }

      it "copies the linked source's enabled attributes and severs the link" do
        source = create(:type)
        field = create(:project_custom_field)
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: field)
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.own_project_custom_field_type_mappings.map(&:custom_field_id)).to contain_exactly(field.id)
      end

      it "copies only the attributes the variant kept active, dropping the ones it disabled",
         with_flag: { type_variants: true } do
        source = create(:type)
        kept = create(:project_custom_field)
        disabled = create(:project_custom_field)
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: kept)
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: disabled)
        type.link!(aspect, source:)
        type.configuration_links.find_by(aspect:).update!(excluded_elements: [disabled.attribute_name])

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).to be_success
        expect(type.own_project_custom_field_type_mappings.map(&:custom_field_id)).to contain_exactly(kept.id)
      end
    end

    context "with the empty mode (project attributes)" do
      let(:aspect) { Type::ConfigurationLink::PROJECT_ATTRIBUTES }

      it "clears the type's own enabled attributes and severs the link" do
        source = create(:type)
        field = create(:project_custom_field)
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: field)
        stale = create(:project_custom_field)
        ProjectCustomFieldTypeMapping.create!(type:, project_custom_field: stale)
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::EMPTY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.own_project_custom_field_type_mappings).to be_empty
      end
    end

    context "with the default mode (pdf export)" do
      let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

      it "resets to the administrator defaults and severs the link" do
        type.pdf_export_templates.disable_all
        type.save!
        type.link!(aspect, source: create(:type))

        result = service.call(mode: WorkPackageTypes::IndependentMode::DEFAULT)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.pdf_export_templates_config).to eq(Type.new.pdf_export_templates_config)
        expect(type.pdf_export_templates.list).to all(have_attributes(enabled: true))
      end
    end

    context "with a mode not available for the aspect" do
      let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

      it "fails and leaves the link untouched" do
        type.link!(aspect, source: create(:type))

        result = service.call(mode: WorkPackageTypes::IndependentMode::EMPTY)

        expect(result).not_to be_success
        expect(type.reload).to be_linked(aspect)
      end
    end

    context "when the seed fails" do
      let(:aspect) { Type::ConfigurationLink::DEFAULTS }

      it "leaves the link untouched" do
        allow_any_instance_of(WorkPackageTypes::CopyConfiguration::DefaultsService) # rubocop:disable RSpec/AnyInstance
          .to receive(:call).and_return(ServiceResult.failure(result: type))
        type.link!(aspect, source: create(:type))

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).not_to be_success
        expect(type.reload).to be_linked(aspect)
      end
    end
  end
end
