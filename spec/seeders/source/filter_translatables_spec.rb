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

RSpec.describe Source::FilterTranslatables do
  subject(:loader) do
    described_module = described_class
    Class.new do
      include described_module
    end.new
  end

  describe "#filter_translatables" do
    it "keeps only keys with t_ prefix" do
      hash = {
        "t_title" => "Welcome to OpenProject",
        "t_text" => "Learn how to plan projects efficiently.",
        "icon" => ":smile:"
      }
      expect(loader.filter_translatables(hash)).to eq(
        "title" => "Welcome to OpenProject",
        "text" => "Learn how to plan projects efficiently."
      )
    end

    it 'does not alter names of keys having "t_" in their names' do
      hash = {
        "welcome_at_home" => {
          "t_title" => "Welcome to OpenProject",
          "t_text" => "Learn how to plan projects efficiently.",
          "icon" => ":smile:"
        }
      }
      expect(loader.filter_translatables(hash)).to eq(
        "welcome_at_home" => {
          "title" => "Welcome to OpenProject",
          "text" => "Learn how to plan projects efficiently."
        }
      )
    end

    it "replaces translatable arrays with hashes indexed by array position" do
      hash = {
        "t_categories" => [
          "First",
          "Second",
          "Third"
        ],
        "allowed_values" => ["yes", "no"]
      }
      expect(loader.filter_translatables(hash)).to eq(
        "categories" => {
          "item_0" => "First",
          "item_1" => "Second",
          "item_2" => "Third"
        }
      )
    end

    it "consider translatables only at the first level" do
      hash = {
        "t_categories" => [
          { "name" => "discarded as it is not translatable" },
          { "t_name" => "kept as it is translatable" },
          "Kept too as the parent key is translatable"
        ]
      }
      expect(loader.filter_translatables(hash)).to eq(
        "categories" => {
          "item_1" => { "name" => "kept as it is translatable" },
          "item_2" => "Kept too as the parent key is translatable"
        }
      )
    end

    it "replaces arrays of translatables with hashes indexed by array position" do
      hash = {
        "categories" => [
          {
            "t_name" => "First"
          }, {
            "t_name" => "Second"
          }, {
            "name" => "This one is discarded as it is not translatable (no t_ prefix)"
          }, {
            "t_name" => "Fourth"
          }
        ]
      }
      expect(loader.filter_translatables(hash)).to eq(
        "categories" => {
          "item_0" => { "name" => "First" },
          "item_1" => { "name" => "Second" },
          "item_3" => { "name" => "Fourth" }
        }
      )
    end

    it "discards empty arrays and hashes" do
      hash = {
        "categories" => [],
        "main" => {},
        "work_packages" => [
          {
            "custom_values" => {}
          }
        ],
        "meta" => {
          "allowed_values" => []
        }
      }
      expect(loader.filter_translatables(hash)).to eq({})
    end

    it "keeps nested structures having translatable keys inside it" do
      hash = {
        "welcome" => {
          "t_title" => "Welcome to OpenProject",
          "t_text" => "Learn how to plan projects efficiently.",
          "icon" => ":smile:"
        }
      }
      expect(loader.filter_translatables(hash)).to eq(
        "welcome" => {
          "title" => "Welcome to OpenProject",
          "text" => "Learn how to plan projects efficiently."
        }
      )
    end

    it "rejects nested structures without any translatable keys inside it" do
      hash = {
        "welcome" => {
          "t_title" => "Welcome to OpenProject"
        },
        "position" => {
          "x" => 18,
          "y" => 76
        }
      }
      expect(loader.filter_translatables(hash)).to eq(
        "welcome" => {
          "title" => "Welcome to OpenProject"
        }
      )
    end
  end
end
