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

RSpec.describe Source::SeedData do
  subject(:seed_data) { described_class.new({}) }

  describe "#store_reference / find_reference" do
    it "acts as a key store to register object by a symbol" do
      object = Object.new
      seed_data.store_reference(:ref, object)
      expect(seed_data.find_reference(:ref)).to be(object)
    end

    it "stores nothing if reference is nil" do
      object = Object.new
      seed_data.store_reference(nil, object)
      seed_data.store_reference(nil, object)
    end

    it "returns nil if reference is nil" do
      expect(seed_data.find_reference(nil)).to be_nil
      object = Object.new
      seed_data.store_reference(nil, object)
      expect(seed_data.find_reference(nil)).to be_nil
      expect(seed_data.find_reference(nil, default: "hello")).to be_nil
    end

    it "raises an error when the reference is already used" do
      seed_data.store_reference(:ref, Object.new)
      expect { seed_data.store_reference(:ref, Object.new) }
        .to raise_error(ArgumentError)
    end

    it "raises an error if the reference is not found" do
      expect { seed_data.find_reference(:ref) }
        .to raise_error(ArgumentError, "Nothing registered with reference :ref")
      expect { seed_data.find_reference(:ref, :other_ref) }
        .to raise_error(ArgumentError, "Nothing registered with references :ref and :other_ref")
      expect { seed_data.find_reference(:ref, :other_ref, :yet_another_ref) }
        .to raise_error(ArgumentError, "Nothing registered with references :ref, :other_ref, and :yet_another_ref")
    end

    it "returns the given default value if the reference is not found" do
      expect(seed_data.find_reference(:ref, default: 42)).to eq(42)
      expect(seed_data.find_reference(:ref, default: "hello")).to eq("hello")
      expect(seed_data.find_reference(:ref, default: nil)).to be_nil
    end

    it "tries with fallback references if the primary reference is not found" do
      object = Object.new
      seed_data.store_reference(:other_ref, object)
      expect(seed_data.find_reference(:other_ref)).to be(object)
      expect(seed_data.find_reference(:ref, :other_ref)).to be(object)
      expect(seed_data.find_reference(:ref, :unknown_ref, :another_unknown, :other_ref)).to be(object)
    end
  end

  describe "#only" do
    let(:original_seed_data) do
      described_class.new(
        "cats" => ["Oreo", "Billy"],
        "dogs" => ["Rex", "Volt"]
      )
    end

    it "creates a copy of the seeding with only the given top level keys" do
      seed_data_dogs_only = original_seed_data.only("dogs")
      expect(seed_data_dogs_only.lookup("cats")).to be_nil
      expect(seed_data_dogs_only.lookup("dogs")).to eq(["Rex", "Volt"])
    end

    it "creates a copy of the inner registry storing references" do
      seed_data_dogs_only = original_seed_data.only("dogs")
      seed_data_dogs_only.store_reference(:ref, "Puppy")
      expect(seed_data_dogs_only.find_reference(:ref)).to eq "Puppy"
      expect(original_seed_data.find_reference(:ref, default: nil)).not_to eq "Puppy"
    end
  end

  describe "#merge" do
    let(:dogs_seed_data) do
      described_class.new("dogs" => ["Rex", "Volt"])
    end
    let(:cats_seed_data) do
      described_class.new("cats" => ["Oreo", "Billy"])
    end

    it "creates a new seed data instance with the data merged from both" do
      merged_seed_data = dogs_seed_data.merge(cats_seed_data)
      merged_seed_data.lookup("cats")
      expect(merged_seed_data.lookup("cats")).to eq(["Oreo", "Billy"])
      expect(merged_seed_data.lookup("dogs")).to eq(["Rex", "Volt"])
    end

    it "creates a new seed data instance with the registry merged from both" do
      dogs_seed_data.store_reference(:best_dog, "Pitou")
      cats_seed_data.store_reference(:best_cat, "Kuzco")
      merged_seed_data = dogs_seed_data.merge(cats_seed_data)
      expect(merged_seed_data.find_reference(:best_dog)).to eq "Pitou"
      expect(merged_seed_data.find_reference(:best_cat)).to eq "Kuzco"
      # no leaking in original data
      expect(dogs_seed_data.find_reference(:best_cat, default: nil)).to be_nil
      expect(cats_seed_data.find_reference(:best_dog, default: nil)).to be_nil
    end

    it "on conflicts, the keys from the given seed data are used" do
      dogs_seed_data.store_reference(:best_animal, "Balto the dog")
      cats_seed_data.store_reference(:best_animal, "Figaro the cat")
      merged_seed_data = dogs_seed_data.merge(cats_seed_data)
      expect(merged_seed_data.find_reference(:best_animal)).to eq("Figaro the cat")

      merged_seed_data = dogs_seed_data.merge(described_class.new("dogs" => ["Scooby-Doo", "Droopy"]))
      merged_seed_data.lookup(:dogs)
      expect(merged_seed_data.lookup("dogs")).to eq(["Scooby-Doo", "Droopy"])
      expect(dogs_seed_data.lookup("dogs")).to eq(["Rex", "Volt"])
    end
  end
end
