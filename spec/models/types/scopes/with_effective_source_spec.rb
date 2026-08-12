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

RSpec.describe Types::Scopes::WithEffectiveSource, with_flag: { type_variants: true } do
  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }
  let(:owner) { create(:type) }
  let(:middle) { create(:type) }
  let(:type) { create(:type) }

  def loaded(ids, for_aspect = aspect)
    Type.with_effective_source(for_aspect).where(id: ids)
  end

  describe "the resolved source" do
    it "hands back the type itself when it owns the aspect" do
      record = loaded(type.id).first

      expect(record.effective_source_for(aspect)).to eq(type)
    end

    it "hands back the owning type at the end of the chain" do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type:, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_2])

      record = loaded(type.id).first

      expect(record.effective_source_for(aspect)).to eq(owner)
      expect(record.effective_excluded_elements(aspect))
        .to contain_exactly("custom_field_1", "custom_field_2")
    end

    it "hands back the type itself on a cyclic chain" do
      other = create(:type)
      create(:type_configuration_link, type:, source: other, aspect:)
      build(:type_configuration_link, type: other, source: type, aspect:).save!(validate: false)

      expect(loaded(type.id).first.effective_source_for(aspect)).to eq(type)
    end

    it "resolves each record of a collection to its own source" do
      create(:type_configuration_link, type: middle, source: owner, aspect:)
      create(:type_configuration_link, type:, source: middle, aspect:)

      records = loaded([owner.id, middle.id, type.id]).index_by(&:id)

      expect(records[owner.id].effective_source_for(aspect)).to eq(owner)
      expect(records[middle.id].effective_source_for(aspect)).to eq(owner)
      expect(records[type.id].effective_source_for(aspect)).to eq(owner)
    end
  end

  describe "query count" do
    before do
      create(:type_configuration_link, type: middle, source: owner, aspect:)
      create(:type_configuration_link, type:, source: middle, aspect:)
    end

    it "resolves the whole collection in one query when it contains its own sources" do
      expect do
        loaded([owner.id, middle.id, type.id]).each { |record| record.effective_source_for(aspect) }
      end.to have_a_query_limit(1)
    end

    it "spends one additional query when the source is outside the loaded set" do
      expect do
        loaded(type.id).each { |record| record.effective_source_for(aspect) }
      end.to have_a_query_limit(2)
    end

    it "still reads the exclusions off the record" do
      records = loaded([owner.id, middle.id, type.id]).to_a

      expect { records.each { |record| record.effective_excluded_elements(aspect) } }
        .to have_a_query_limit(0)
    end

    it "resolves several chained aspects without a query per aspect" do
      create(:type_configuration_link, type:, source: owner,
                                       aspect: Type::ConfigurationLink::PDF_EXPORT)

      relation = Type.with_effective_source(aspect)
                     .with_effective_source(Type::ConfigurationLink::PDF_EXPORT)
                     .where(id: [owner.id, middle.id, type.id])

      expect do
        relation.each do |record|
          record.effective_source_for(aspect)
          record.effective_source_for(Type::ConfigurationLink::PDF_EXPORT)
        end
      end.to have_a_query_limit(1)
    end
  end

  describe "without the scope" do
    before do
      create(:type_configuration_link, type:, source: owner, aspect:)
    end

    it "resolves by querying instead" do
      expect(Type.find(type.id).effective_source_for(aspect)).to eq(owner)
    end

    it "resolves an aspect the relation did not preload" do
      create(:type_configuration_link, type:, source: middle,
                                       aspect: Type::ConfigurationLink::PDF_EXPORT)

      record = loaded(type.id).first

      expect(record.effective_source_for(Type::ConfigurationLink::PDF_EXPORT)).to eq(middle)
    end
  end

  describe "staleness" do
    it "stops answering from the preloaded source after a reload" do
      create(:type_configuration_link, type:, source: owner, aspect:)

      record = loaded(type.id).first
      expect(record.effective_source_for(aspect)).to eq(owner)

      record.configuration_links.destroy_all
      record.reload

      expect(record.effective_source_for(aspect)).to eq(type)
    end
  end

  describe "with the flag off", with_flag: { type_variants: false } do
    it "hands back the type itself" do
      create(:type_configuration_link, type:, source: owner, aspect:)

      expect(loaded(type.id).first.effective_source_for(aspect)).to eq(type)
    end
  end
end
