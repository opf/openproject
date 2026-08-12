# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersistedQuery do
  # The base class has no serializers installed (the `inherited` hook only
  # installs them on subclasses), so `filters`/`orders`/`selects` must be
  # initialised explicitly for validations from Queries::BaseQuery to pass.
  subject(:persisted_query) do
    described_class.new(name: "My query", filters: [], orders: [], selects: [])
  end

  describe "validations" do
    it "is valid with a name" do
      expect(persisted_query).to be_valid
    end

    it "rejects names longer than 255 characters" do
      persisted_query.name = "a" * 256
      expect(persisted_query).not_to be_valid
      expect(persisted_query.errors[:name]).to be_present
    end

    it "accepts names of exactly 255 characters" do
      persisted_query.name = "a" * 255
      expect(persisted_query).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:project).optional }
    it { is_expected.to belong_to(:principal).optional }

    it "has many views with restrict_with_error" do
      association = described_class.reflect_on_association(:views)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:as]).to eq(:query)
      expect(association.options[:dependent]).to eq(:restrict_with_error)
      expect(association.options[:class_name]).to eq("PersistedView")
    end
  end

  describe "persistence" do
    it "can be saved and reloaded" do
      persisted_query.save!
      expect(described_class.find(persisted_query.id)).to be_present
    end

    it "prevents deletion when views reference it" do
      persisted_query.save!
      PersistedView.create!(name: "V", query: persisted_query)

      expect { persisted_query.destroy }.not_to change(described_class, :count)
      expect(persisted_query.errors[:base]).to include("Cannot delete record because dependent views exist")
    end
  end
end
