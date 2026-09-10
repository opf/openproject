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

  describe "group_bys" do
    it "defaults to none" do
      expect(persisted_query.group_bys).to eq([])
    end

    it "is stored as an empty array" do
      persisted_query.save!

      raw = described_class.connection.select_value(
        "SELECT group_bys FROM persisted_queries WHERE id = #{persisted_query.id}"
      )

      expect(JSON.parse(raw)).to eq([])
    end

    # The base class gets no serializers - the `inherited` hook only installs
    # them on subclasses.
    it "installs a group by serializer on subclasses" do
      expect(UserQuery.type_for_attribute(:group_bys).coder)
        .to be_a(Queries::Serialization::GroupBys)
    end

    # TODO: round trip actual group bys through the column once a PersistedQuery
    # subclass registers some. UserQuery registers none, so anything it could be
    # grouped by is a NotExistingGroupBy, which only tests the degraded path.
    # CostReportQuery will be the first real one.
  end
end
