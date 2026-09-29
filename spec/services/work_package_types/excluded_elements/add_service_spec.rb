# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe WorkPackageTypes::ExcludedElements::AddService, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }
  let(:source) { create(:type).default_variant }
  let(:variant) { create(:type).default_variant }

  subject(:service_call) { described_class.new(user: admin, variant:).call(aspect:, elements: %w[custom_field_1]) }

  def excluded_elements
    excluded_configuration_elements(variant, aspect: aspect)
  end

  context "when the variant is Linked for the aspect" do
    before { link_configuration(variant, source:, aspect:) }

    it "excludes the element" do
      expect(service_call).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1")
    end

    it "keeps the elements already excluded" do
      exclude_configuration_elements(variant, aspect:, elements: %w[assignee])

      expect(service_call).to be_success
      expect(excluded_elements).to contain_exactly("assignee", "custom_field_1")
    end

    it "does not store an element twice" do
      exclude_configuration_elements(variant, aspect:, elements: %w[custom_field_1])

      expect(service_call).to be_success
      expect(excluded_elements).to eq(%w[custom_field_1])
    end

    it "excludes several elements at once" do
      result = described_class.new(user: admin, variant:)
                             .call(aspect:, elements: ["custom_field_1", "assignee", "query_7"])

      expect(result).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1", "assignee", "query_7")
    end

    it "normalises the given elements" do
      result = described_class.new(user: admin, variant:)
                             .call(aspect:, elements: ["  custom_field_1  ", "", nil, :assignee])

      expect(result).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1", "assignee")
    end

    it "recomputes from the persisted list, not from a stale read" do
      stale = TypeVariant.find(variant.id)
      exclude_configuration_elements(variant, aspect:, elements: %w[assignee])

      expect(described_class.new(user: admin, variant: stale).call(aspect:, elements: %w[custom_field_1]))
        .to be_success
      expect(excluded_elements).to contain_exactly("assignee", "custom_field_1")
    end

    it "narrows what the variant inherits" do
      source.update!(attribute_groups: [["numbers", %w[assignee responsible]]])
      described_class.new(user: admin, variant:).call(aspect:, elements: %w[assignee])

      expect(variant.reload.attribute_groups.first.attributes).to eq(%w[responsible])
    end

    it "leaves the link's source untouched" do
      expect { service_call }.not_to change { variant.reload.form_configuration_source_id }
    end

    it "does not touch another aspect's link" do
      link_configuration(variant, source:, aspect: TypeVariant::PROJECT_ATTRIBUTES)

      service_call

      expect(excluded_configuration_elements(variant, aspect: TypeVariant::PROJECT_ATTRIBUTES)).to be_empty
    end
  end

  context "when the variant owns the aspect" do
    it "fails and explains that there is nothing to exclude" do
      expect(service_call).to be_failure
      expect(service_call.errors.full_messages.join)
        .to include(I18n.t("types.edit.reuse_mode.exclusions.not_inherited"))
    end
  end

  context "with an unknown aspect" do
    before { link_configuration(variant, source:, aspect:) }

    it "fails rather than writing anything" do
      result = described_class.new(user: admin, variant:).call(aspect: "bogus", elements: %w[custom_field_1])

      expect(result).to be_failure
      expect(excluded_elements).to be_empty
    end
  end
end
