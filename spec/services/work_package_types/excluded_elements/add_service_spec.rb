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

  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }
  let(:source) { create(:type) }
  let(:type) { create(:type) }

  subject(:service_call) { described_class.new(user: admin, type:).call(aspect:, elements: %w[custom_field_1]) }

  def excluded_elements
    type.configuration_links.find_by(aspect:)&.reload&.excluded_elements
  end

  context "when the type is Linked for the aspect" do
    let!(:link) { create(:type_configuration_link, type:, source:, aspect:) }

    it "excludes the element" do
      expect(service_call).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1")
    end

    it "keeps the elements already excluded" do
      link.update!(excluded_elements: %w[assignee])

      expect(service_call).to be_success
      expect(excluded_elements).to contain_exactly("assignee", "custom_field_1")
    end

    it "does not store an element twice" do
      link.update!(excluded_elements: %w[custom_field_1])

      expect(service_call).to be_success
      expect(excluded_elements).to eq(%w[custom_field_1])
    end

    it "excludes several elements at once" do
      result = described_class.new(user: admin, type:)
                             .call(aspect:, elements: ["custom_field_1", "assignee", "query_7"])

      expect(result).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1", "assignee", "query_7")
    end

    it "normalises the given elements" do
      result = described_class.new(user: admin, type:)
                             .call(aspect:, elements: ["  custom_field_1  ", "", nil, :assignee])

      expect(result).to be_success
      expect(excluded_elements).to contain_exactly("custom_field_1", "assignee")
    end

    # Two switches toggled at once contend for the one array column, so the write has to
    # recompute from the row rather than from the copy loaded before the lock was taken.
    it "recomputes from the persisted list, not from a stale read" do
      allow(type.configuration_links).to receive(:find_by).and_return(link)
      Type::ConfigurationLink.find(link.id).update!(excluded_elements: %w[assignee])

      expect(service_call).to be_success
      expect(excluded_elements).to contain_exactly("assignee", "custom_field_1")
    end

    it "narrows what the type inherits" do
      source.update!(attribute_groups: [["numbers", %w[assignee responsible]]])
      described_class.new(user: admin, type:).call(aspect:, elements: %w[assignee])

      expect(type.reload.attribute_groups.first.attributes).to eq(%w[responsible])
    end

    it "leaves the link's source untouched" do
      expect { service_call }.not_to change { link.reload.source_id }
    end

    it "does not touch another aspect's link" do
      other = create(:type_configuration_link, type:, source:,
                                               aspect: Type::ConfigurationLink::PDF_EXPORT)

      service_call

      expect(other.reload.excluded_elements).to be_empty
    end
  end

  context "when the type owns the aspect" do
    it "fails and explains that there is nothing to exclude" do
      expect(service_call).to be_failure
      expect(service_call.errors.full_messages.join)
        .to include(I18n.t("types.edit.reuse_mode.exclusions.not_linked"))
    end
  end

  context "with an unknown aspect" do
    let!(:link) { create(:type_configuration_link, type:, source:, aspect:) }

    it "fails rather than writing anything" do
      result = described_class.new(user: admin, type:).call(aspect: "bogus", elements: %w[custom_field_1])

      expect(result).to be_failure
      expect(excluded_elements).to be_empty
    end
  end
end
