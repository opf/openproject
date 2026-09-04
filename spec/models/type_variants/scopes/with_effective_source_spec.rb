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

RSpec.describe TypeVariants::Scopes::WithEffectiveSource do
  def link(variant, source:, excluded: [])
    variant.update!("#{aspect}_source": source, "#{aspect}_excluded_elements": excluded)
  end

  def link_without_validation(variant, source:)
    variant.update_column(:"#{aspect}_source_id", source.id)
  end

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }
  let(:owner) { create(:type).default_variant }
  let(:middle) { create(:type).default_variant }
  let(:type) { create(:type).default_variant }

  def loaded(ids, for_aspect = aspect)
    TypeVariant.with_effective_source(for_aspect).where(id: ids)
  end

  describe "the resolved source" do
    it "hands back the type itself when it owns the aspect" do
      record = loaded(type.id).first

      expect(record.effective_source_for(aspect)).to eq(type)
    end

    it "hands back the owning type at the end of the chain" do
      link(middle, source: owner, excluded: %w[custom_field_1])
      link(type, source: middle, excluded: %w[custom_field_2])

      record = loaded(type.id).first

      expect(record.effective_source_for(aspect)).to eq(owner)
      expect(record.effective_excluded_elements(aspect))
        .to contain_exactly("custom_field_1", "custom_field_2")
    end

    it "hands back the type itself on a cyclic chain" do
      other = create(:type).default_variant
      link(type, source: other)
      link_without_validation(other, source: type)

      expect(loaded(type.id).first.effective_source_for(aspect)).to eq(type)
    end

    it "resolves each record of a collection to its own source" do
      link(middle, source: owner)
      link(type, source: middle)

      records = loaded([owner.id, middle.id, type.id]).index_by(&:id)

      expect(records[owner.id].effective_source_for(aspect)).to eq(owner)
      expect(records[middle.id].effective_source_for(aspect)).to eq(owner)
      expect(records[type.id].effective_source_for(aspect)).to eq(owner)
    end
  end

  describe "query count" do
    before do
      link(middle, source: owner)
      link(type, source: middle)
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
      type.update!(pdf_export_source: owner)

      relation = TypeVariant.with_effective_source(aspect)
                     .with_effective_source(TypeVariant::PDF_EXPORT)
                     .where(id: [owner.id, middle.id, type.id])

      expect do
        relation.each do |record|
          record.effective_source_for(aspect)
          record.effective_source_for(TypeVariant::PDF_EXPORT)
        end
      end.to have_a_query_limit(1)
    end
  end

  describe "without the scope" do
    before do
      link(type, source: owner)
    end

    it "resolves by querying instead" do
      expect(TypeVariant.find(type.id).effective_source_for(aspect)).to eq(owner)
    end

    it "resolves an aspect the relation did not preload" do
      type.update!(pdf_export_source: middle)

      record = loaded(type.id).first

      expect(record.effective_source_for(TypeVariant::PDF_EXPORT)).to eq(middle)
    end
  end

  describe "staleness" do
    it "stops answering from the preloaded source after a reload" do
      link(type, source: owner)

      record = loaded(type.id).first
      expect(record.effective_source_for(aspect)).to eq(owner)

      record.update!("#{aspect}_source": nil)
      record.reload

      expect(record.effective_source_for(aspect)).to eq(type)
    end
  end

  describe "with the flag off", with_flag: { type_variants: false } do
    it "resolves to the source just the same" do
      link(type, source: owner)

      expect(loaded(type.id).first.effective_source_for(aspect)).to eq(owner)
    end
  end
end
