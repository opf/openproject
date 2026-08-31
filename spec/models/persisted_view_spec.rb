# frozen_string_literal: true

require "rails_helper"

RSpec.describe PersistedView do
  subject(:persisted_view) { described_class.new(name: "My view") }

  describe "validations" do
    it "is valid with a name" do
      expect(persisted_view).to be_valid
    end

    it "requires a name" do
      persisted_view.name = nil
      expect(persisted_view).not_to be_valid
      expect(persisted_view.errors[:name]).to be_present
    end

    it "rejects names longer than 255 characters" do
      persisted_view.name = "a" * 256
      expect(persisted_view).not_to be_valid
      expect(persisted_view.errors[:name]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:project).optional }
    it { is_expected.to belong_to(:principal).optional }
    it { is_expected.to belong_to(:query).optional }
    it { is_expected.to belong_to(:parent).class_name("PersistedView").optional }

    it "has many children that are destroyed with the parent" do
      association = described_class.reflect_on_association(:children)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:class_name]).to eq("PersistedView")
      expect(association.options[:foreign_key]).to eq("parent_id")
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "allows a polymorphic query association" do
      reflection = described_class.reflect_on_association(:query)
      expect(reflection.options[:polymorphic]).to be true
    end
  end

  describe "favoritable" do
    it "acts as favoritable" do
      expect(described_class).to respond_to(:acts_as_favoritable)
      expect(persisted_view).to respond_to(:favorites)
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:public_view) { described_class.create!(name: "Public", public: true) }
    let!(:own_private_view) { described_class.create!(name: "Own", public: false, principal: user) }
    let!(:other_private_view) { described_class.create!(name: "Other", public: false, principal: other_user) }

    describe ".public_views" do
      it "returns only public views" do
        expect(described_class.public_views).to contain_exactly(public_view)
      end
    end

    describe ".private_views" do
      it "returns private views for the given principal" do
        expect(described_class.private_views(user)).to contain_exactly(own_private_view)
      end

      it "defaults to User.current when no principal is given" do
        login_as(user)
        expect(described_class.private_views).to contain_exactly(own_private_view)
      end
    end

    describe ".visible" do
      it "returns public views and the principal's own private views" do
        expect(described_class.visible(user)).to contain_exactly(public_view, own_private_view)
      end

      it "excludes other principals' private views" do
        expect(described_class.visible(user)).not_to include(other_private_view)
      end

      it "defaults to User.current when no principal is given" do
        login_as(user)
        expect(described_class.visible).to contain_exactly(public_view, own_private_view)
      end
    end
  end

  describe "category enum" do
    it "allows the defined category values" do
      %w[work_package project resource_management].each do |value|
        view = described_class.new(name: "V", category: value)
        expect(view).to be_valid
        expect(view.category).to eq(value)
      end
    end

    it "allows nil as a category" do
      persisted_view.category = nil
      expect(persisted_view).to be_valid
    end

    it "rejects unknown category values" do
      persisted_view.category = "unknown"
      expect(persisted_view).not_to be_valid
      expect(persisted_view.errors[:category]).to be_present
    end

    it "exposes predicate methods for each category" do
      view = described_class.new(name: "V", category: "work_package")
      expect(view).to be_work_package
      expect(view).not_to be_project
      expect(view).not_to be_resource_management
    end

    it "exposes scopes for each category" do
      wp_view = described_class.create!(name: "WP", category: "work_package")
      project_view = described_class.create!(name: "P", category: "project")
      rm_view = described_class.create!(name: "RM", category: "resource_management")

      expect(described_class.work_package).to contain_exactly(wp_view)
      expect(described_class.project).to contain_exactly(project_view)
      expect(described_class.resource_management).to contain_exactly(rm_view)
    end
  end

  describe "#effective_query" do
    let(:query) { PersistedQuery.create!(name: "Q", filters: [], orders: [], selects: []) }

    # The parent/child class validation requires the parent to declare its
    # children class. PersistedView is its own parent and child here, so we
    # allow it for the duration of these examples.
    around do |example|
      previous = described_class.allowed_children
      described_class.allowed_children = previous + [described_class.name]
      example.run
    ensure
      described_class.allowed_children = previous
    end

    it "returns its own query when set" do
      view = described_class.create!(name: "V", query:)
      expect(view.effective_query).to eq(query)
    end

    it "returns the parent's query when no own query is set" do
      parent = described_class.create!(name: "Parent", query:)
      child = described_class.create!(name: "Child", parent:)
      expect(child.effective_query).to eq(query)
    end

    it "walks up the parent chain until a query is found" do
      root = described_class.create!(name: "Root", query:)
      middle = described_class.create!(name: "Middle", parent: root)
      leaf = described_class.create!(name: "Leaf", parent: middle)
      expect(leaf.effective_query).to eq(query)
    end

    it "returns nil when neither the view nor any ancestor has a query" do
      parent = described_class.create!(name: "Parent")
      child = described_class.create!(name: "Child", parent:)
      expect(child.effective_query).to be_nil
    end
  end

  describe "parent/children lifecycle" do
    it "destroys children when the parent is destroyed" do
      parent = described_class.create!(name: "Parent")
      described_class.allowed_children = [described_class.name]
      described_class.create!(name: "Child", parent:)

      expect { parent.destroy }.to change(described_class, :count).by(-2)
    ensure
      described_class.allowed_children = []
    end
  end

  describe "parent/child class validation" do
    let(:parent_class) do
      Class.new(described_class) { self.allowed_children = ["AllowedChild"] }
    end
    let(:allowed_child_class) do
      klass = Class.new(described_class)
      stub_const("AllowedChild", klass)
      klass
    end
    let(:disallowed_child_class) do
      klass = Class.new(described_class)
      stub_const("DisallowedChild", klass)
      klass
    end

    it "is valid when the parent's allowed_children includes this class" do
      parent_class
      parent = parent_class.new(name: "Parent")
      child = allowed_child_class.new(name: "Child", parent:)
      expect(child).to be_valid
    end

    it "is invalid when the parent's allowed_children does not include this class" do
      parent_class
      parent = parent_class.new(name: "Parent")
      child = disallowed_child_class.new(name: "Child", parent:)
      expect(child).not_to be_valid
      expect(child.errors.symbols_for(:parent)).to include(:invalid_child_for_parent)
    end

    it "is valid when no parent is set, regardless of allowed_children" do
      view = described_class.new(name: "Top-level")
      expect(view).to be_valid
    end
  end

  describe "#visible?" do
    it "raises SubclassResponsibilityError on the abstract base class" do
      view = described_class.new(name: "V")
      expect { view.visible?(build(:user)) }.to raise_error(SubclassResponsibilityError)
    end
  end

  describe ".allowed_children" do
    let(:base_class) { Class.new(described_class) }
    let(:other_class) { Class.new(described_class) }

    it "defaults to an empty array" do
      expect(base_class.allowed_children).to eq([])
    end

    it "is isolated per subclass when mutated" do
      base_class.allowed_children << "Foo"

      expect(base_class.allowed_children).to eq(["Foo"])
      expect(other_class.allowed_children).to eq([])
      expect(described_class.allowed_children).to eq([])
    end

    it "can be assigned per subclass without leaking to siblings" do
      base_class.allowed_children = %w[Foo Bar]

      expect(base_class.allowed_children).to eq(%w[Foo Bar])
      expect(described_class.allowed_children).to eq([])
    end
  end
end
