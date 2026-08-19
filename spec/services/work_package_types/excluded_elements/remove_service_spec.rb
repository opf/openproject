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

RSpec.describe WorkPackageTypes::ExcludedElements::RemoveService, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }
  let(:source) { create(:type).default_variant }
  let(:variant) { create(:type).default_variant }

  subject(:service_call) { described_class.new(user: admin, variant:).call(aspect:, elements: %w[custom_field_1]) }

  def excluded_elements
    excluded_configuration_elements(variant, aspect: aspect)
  end

  context "when the variant is Linked for the aspect" do
    let!(:link) do
      link_configuration(variant, source:, aspect: aspect, excluded: %w[custom_field_1 assignee])
    end

    it "lets the element be inherited again" do
      expect(service_call).to be_success
      expect(excluded_elements).to contain_exactly("assignee")
    end

    it "leaves an element that was not excluded alone" do
      result = described_class.new(user: admin, variant:).call(aspect:, elements: %w[custom_field_99])

      expect(result).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1", "assignee")
    end

    it "can clear the last exclusion" do
      result = described_class.new(user: admin, variant:)
                             .call(aspect:, elements: %w[custom_field_1 assignee])

      expect(result).to be_success
      expect(excluded_elements).to be_empty
    end

    it "restores the element to what the type inherits" do
      source.update!(attribute_groups: [["numbers", %w[assignee responsible]]])
      described_class.new(user: admin, variant:).call(aspect:, elements: %w[assignee])

      expect(variant.reload.attribute_groups.first.attributes).to eq(%w[assignee responsible])
    end

    it "does not touch another aspect's link" do
      link_configuration(variant, source:, aspect: TypeVariant::PROJECT_ATTRIBUTES, excluded: %w[custom_field_1])

      service_call

      expect(excluded_configuration_elements(variant, aspect: TypeVariant::PROJECT_ATTRIBUTES))
        .to contain_exactly("custom_field_1")
    end
  end

  context "when an ancestor's link excludes the element" do
    let(:owner) { create(:type).default_variant }

    before do
      link_configuration(source, source: owner, aspect:, excluded: %w[assignee])
      link_configuration(variant, source:, aspect:)
    end

    it "does not remove it from the ancestor's link" do
      owner.update!(attribute_groups: [["numbers", %w[assignee responsible]]])

      result = described_class.new(user: admin, variant:).call(aspect:, elements: %w[assignee])

      expect(result).to be_success
      expect(excluded_configuration_elements(source, aspect:)).to contain_exactly("assignee")
      expect(variant.reload.effective_excluded_elements(aspect)).to contain_exactly("assignee")
    end
  end

  context "when the variant owns the aspect" do
    it "fails and explains that there is nothing to exclude" do
      expect(service_call).to be_failure
      expect(service_call.errors.full_messages.join)
        .to include(I18n.t("types.edit.reuse_mode.exclusions.not_linked"))
    end
  end

  context "with an unknown aspect" do
    let!(:link) do
      link_configuration(variant, source:, aspect: aspect, excluded: %w[custom_field_1])
    end

    it "fails rather than writing anything" do
      result = described_class.new(user: admin, variant:).call(aspect: "bogus", elements: %w[custom_field_1])

      expect(result).to be_failure
      expect(excluded_elements).to contain_exactly("custom_field_1")
    end
  end
end
