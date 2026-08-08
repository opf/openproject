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

RSpec.describe WorkPackageTypes::CopyConfiguration::ProjectAttributesService do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type) }

  subject(:service_call) { described_class.new(type:, user: admin).call(source:) }

  def enabled_field_ids(a_type)
    a_type.own_project_custom_field_type_mappings.reload.map(&:custom_field_id)
  end

  describe "#call" do
    context "with a source" do
      let(:source) { create(:type) }
      let(:source_field) { create(:project_custom_field) }

      before do
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: source_field)
      end

      it "copies the source's enabled project attributes onto the type" do
        expect(service_call).to be_success
        expect(enabled_field_ids(type)).to contain_exactly(source_field.id)
      end

      it "leaves the source untouched" do
        service_call

        expect(enabled_field_ids(source)).to contain_exactly(source_field.id)
      end
    end

    # Going Independent has to preserve the configuration the type was presenting, so the
    # attributes its link chain excluded must not come back as owned rows.
    context "when the type's link excludes some of the source's attributes",
            with_flag: { type_variants: true } do
      let(:source) { create(:type) }
      let(:kept_field) { create(:project_custom_field) }
      let(:excluded_field) { create(:project_custom_field) }

      before do
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: kept_field)
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: excluded_field)
        create(:type_configuration_link, type:, source:,
                                         aspect: Type::ConfigurationLink::PROJECT_ATTRIBUTES,
                                         excluded_elements: [excluded_field.attribute_name])
      end

      it "copies only the attributes the type was actually presenting" do
        expect(service_call).to be_success
        expect(enabled_field_ids(type)).to contain_exactly(kept_field.id)
      end

      it "leaves the source's own mappings complete" do
        service_call

        expect(enabled_field_ids(source)).to contain_exactly(kept_field.id, excluded_field.id)
      end
    end

    context "when the type already has enabled attributes" do
      let(:source) { create(:type) }
      let(:source_field) { create(:project_custom_field) }
      let(:own_field) { create(:project_custom_field) }

      before do
        ProjectCustomFieldTypeMapping.create!(type:, project_custom_field: own_field)
        ProjectCustomFieldTypeMapping.create!(type: source, project_custom_field: source_field)
      end

      it "replaces the type's mappings with the source's" do
        expect(service_call).to be_success
        expect(enabled_field_ids(type)).to contain_exactly(source_field.id)
      end
    end

    context "when the source has no enabled attributes" do
      let(:source) { create(:type) }
      let(:own_field) { create(:project_custom_field) }

      before do
        ProjectCustomFieldTypeMapping.create!(type:, project_custom_field: own_field)
      end

      it "clears the type's mappings" do
        expect(service_call).to be_success
        expect(enabled_field_ids(type)).to be_empty
      end
    end

    context "when the source resolves through a link", with_flag: { type_variants: true } do
      let(:owner) { create(:type) }
      let(:source) { create(:type) }
      let(:owner_field) { create(:project_custom_field) }

      before do
        ProjectCustomFieldTypeMapping.create!(type: owner, project_custom_field: owner_field)
        source.link!(Type::ConfigurationLink::PROJECT_ATTRIBUTES, source: owner)
      end

      it "adopts the resolved owner's enabled attributes" do
        expect(service_call).to be_success
        expect(enabled_field_ids(type)).to contain_exactly(owner_field.id)
      end
    end

    context "with an invalid source" do
      let(:source) { nil }

      it "fails without changing the type" do
        expect(service_call).not_to be_success
      end
    end

    context "when the source is the type itself" do
      let(:source) { type }

      it "fails" do
        expect(service_call).not_to be_success
      end
    end
  end
end
