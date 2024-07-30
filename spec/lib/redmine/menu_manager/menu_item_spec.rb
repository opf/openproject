#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe Redmine::MenuManager::MenuItem do
  describe ".new" do
    it "creates an item with all required parameters" do
      expect(described_class.new(:test_good_menu, "/test", {}))
        .to be_a described_class
    end

    it "creates an item with an if condition" do
      expect(described_class.new(:test_good_menu, "/test", if: ->(*) {}))
        .to be_a described_class
    end

    it "creates an item with extra html options" do
      expect(described_class.new(:test_good_menu, "/test", html: { data: "foo" }))
        .to be_a described_class
    end

    it "creates an item with a children proc" do
      expect(described_class.new(:test_good_menu, "/test", children: ->(*) {}))
        .to be_a described_class
    end

    it "fails without a name" do
      expect { described_class.new }
        .to raise_error ArgumentError
    end

    it "fails without a url" do
      expect { described_class.new(:missing_url) }
        .to raise_error ArgumentError
    end

    it "fails without an options" do
      expect { described_class.new(:missing_url, "/test") }
        .to raise_error ArgumentError
    end

    it "fails when setting the parent item to the current item" do
      expect { described_class.new(:test_error, "/test", parent: :test_error) }
        .to raise_error ArgumentError
    end

    it "fails for an if condition without a proc" do
      expect { described_class.new(:test_error, "/test", if: ["not_a_proc"]) }
        .to raise_error ArgumentError
    end

    it "fails for an html condition without a hash" do
      expect { described_class.new(:test_error, "/test", html: ["not_a_hash"]) }
        .to raise_error ArgumentError
    end

    it "fails for an children optiono without a proc" do
      expect { described_class.new(:test_error, "/test", children: ["not_a_proc"]) }
        .to raise_error ArgumentError
    end
  end
end
