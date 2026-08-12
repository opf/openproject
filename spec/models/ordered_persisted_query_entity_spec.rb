# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderedPersistedQueryEntity do
  let(:persisted_query) do
    PersistedQuery.create!(name: "Q", filters: [], orders: [], selects: [])
  end
  let(:work_package) { create(:work_package) }

  subject(:entry) do
    described_class.new(persisted_query:, entity: work_package, position: 1)
  end

  describe "associations" do
    it { is_expected.to belong_to(:persisted_query).required }

    it "belongs to a polymorphic entity" do
      reflection = described_class.reflect_on_association(:entity)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.options[:polymorphic]).to be true
    end
  end

  describe "validations" do
    it "is valid with a position, query and entity" do
      expect(entry).to be_valid
    end

    it "requires a position" do
      entry.position = nil
      expect(entry).not_to be_valid
      expect(entry.errors[:position]).to be_present
    end

    it "requires a persisted_query" do
      entry.persisted_query = nil
      expect(entry).not_to be_valid
    end

    it "requires an entity" do
      entry.entity = nil
      expect(entry).not_to be_valid
    end

    it "prevents duplicate entries for the same (query, entity_type, entity_id)" do
      described_class.create!(persisted_query:, entity: work_package, position: 1)
      duplicate = described_class.new(persisted_query:, entity: work_package, position: 2)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:entity_id]).to be_present
    end

    it "allows the same entity in a different persisted_query" do
      other_query = PersistedQuery.create!(name: "Other", filters: [], orders: [], selects: [])
      described_class.create!(persisted_query:, entity: work_package, position: 1)

      expect(described_class.new(persisted_query: other_query, entity: work_package, position: 1))
        .to be_valid
    end
  end

  describe "default ordering" do
    it "orders by position ascending" do
      wp1 = create(:work_package)
      wp2 = create(:work_package)
      wp3 = create(:work_package)

      described_class.create!(persisted_query:, entity: wp1, position: 3)
      described_class.create!(persisted_query:, entity: wp2, position: 1)
      described_class.create!(persisted_query:, entity: wp3, position: 2)

      expect(persisted_query.ordered_entities.map(&:entity)).to eq([wp2, wp3, wp1])
    end
  end

  describe "cascade on query deletion" do
    it "is deleted when the persisted_query is destroyed" do
      entry.save!
      expect { persisted_query.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
