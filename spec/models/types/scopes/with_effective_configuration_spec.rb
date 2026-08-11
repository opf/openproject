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

RSpec.describe Types::Scopes::WithEffectiveConfiguration, with_flag: { type_variants: true } do
  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }
  let(:owner) { create(:type) }
  let(:middle) { create(:type) }
  let(:type) { create(:type) }

  def loaded(type_to_load, for_aspect = aspect)
    Type.with_effective_configuration(for_aspect).find(type_to_load.id)
  end

  describe "the preloaded values" do
    it "resolves a type owning the aspect to itself with nothing excluded" do
      record = loaded(type)

      expect(record.effective_source_id(aspect)).to eq(type.id)
      expect(record.effective_excluded_elements(aspect)).to eq([])
    end

    it "resolves through the chain and unions the exclusions along it" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_2 assignee])

      record = loaded(type)

      expect(record.effective_source_id(aspect)).to eq(owner.id)
      expect(record.effective_excluded_elements(aspect))
        .to contain_exactly("custom_field_1", "custom_field_2", "assignee")
    end

    it "resolves a cyclic chain to the type itself with nothing excluded" do
      other = create(:type)
      create(:type_configuration_link, type:, source: other, aspect:,
                                       excluded_elements: %w[custom_field_1])
      build(:type_configuration_link, type: other, source: type, aspect:,
                                      excluded_elements: %w[custom_field_2]).save!(validate: false)

      record = loaded(type)

      expect(record.effective_source_id(aspect)).to eq(type.id)
      expect(record.effective_excluded_elements(aspect)).to eq([])
    end

    it "reports an element excluded at two levels of the chain only once" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_1])

      expect(loaded(type).effective_excluded_elements(aspect)).to eq(["custom_field_1"])
    end

    it "keeps every type in a loaded collection resolved independently" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_2])

      records = Type.with_effective_configuration(aspect)
                    .where(id: [owner.id, middle.id, type.id])
                    .index_by(&:id)

      expect(records[owner.id].effective_excluded_elements(aspect)).to eq([])
      expect(records[middle.id].effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
      expect(records[type.id].effective_excluded_elements(aspect))
        .to contain_exactly("custom_field_1", "custom_field_2")
    end
  end

  describe "reading without further queries" do
    before do
      create(:type_configuration_link, type:, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
    end

    it "reads both values off the record" do
      record = loaded(type)

      expect { record.effective_source_id(aspect) }.to have_a_query_limit(0)
      expect { record.effective_excluded_elements(aspect) }.to have_a_query_limit(0)
    end

    it "resolves a whole collection with a single query" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_2])

      expect do
        Type.with_effective_configuration(aspect).each do |record|
          record.effective_source_id(aspect)
          record.effective_excluded_elements(aspect)
        end
      end.to have_a_query_limit(1)
    end
  end

  describe "falling back to a query" do
    before do
      create(:type_configuration_link, type:, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
    end

    it "queries for a record loaded without the scope" do
      record = Type.find(type.id)

      expect(record.effective_source_id(aspect)).to eq(owner.id)
      expect(record.effective_excluded_elements(aspect)).to contain_exactly("custom_field_1")
    end

    # The columns are aspect-suffixed so that a record preloaded for one aspect misses on
    # another and falls back, rather than answering with the wrong aspect's values.
    it "queries for an aspect other than the preloaded one" do
      create(:type_configuration_link, type:, source: middle,
                                       aspect: Type::ConfigurationLink::PDF_EXPORT,
                                       excluded_elements: %w[contract])

      record = loaded(type)

      expect(record.effective_source_id(Type::ConfigurationLink::PDF_EXPORT)).to eq(middle.id)
      expect(record.effective_excluded_elements(Type::ConfigurationLink::PDF_EXPORT))
        .to contain_exactly("contract")
    end

    it "preloads several aspects at once when chained" do
      create(:type_configuration_link, type:, source: middle,
                                       aspect: Type::ConfigurationLink::PDF_EXPORT,
                                       excluded_elements: %w[contract])

      record = Type.with_effective_configuration(aspect)
                   .with_effective_configuration(Type::ConfigurationLink::PDF_EXPORT)
                   .find(type.id)

      expect { record.effective_excluded_elements(aspect) }.to have_a_query_limit(0)
      expect { record.effective_excluded_elements(Type::ConfigurationLink::PDF_EXPORT) }
        .to have_a_query_limit(0)
      expect(record.effective_excluded_elements(Type::ConfigurationLink::PDF_EXPORT))
        .to contain_exactly("contract")
    end
  end

  describe "with the flag off", with_flag: { type_variants: false } do
    it "ignores the preloaded values" do
      create(:type_configuration_link, type:, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])

      record = loaded(type)

      expect(record.effective_source_id(aspect)).to eq(type.id)
      expect(record.effective_excluded_elements(aspect)).to eq([])
    end
  end

  it "rejects an unknown aspect instead of interpolating it into a column alias" do
    expect { Type.with_effective_configuration("bogus; DROP TABLE types") }
      .to raise_error(ArgumentError, /Unknown configuration aspect/)
  end
end
