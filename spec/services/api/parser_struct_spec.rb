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

RSpec.describe API::ParserStruct do
  let(:instance) { described_class.new }

  describe "assigning a value and method creation" do
    # Dynamically creating a method can be misused when allowing
    # those method are generated based on client input.
    # See "Symbol denial of service" at
    # https://ruby-doc.org/stdlib-3.0.0/libdoc/ostruct/rdoc/OpenStruct.html#class-OpenStruct-label-Caveats.
    it "does not dynamically create a method" do
      instance.some_method = "string"

      expect(instance.methods.grep(/some_method/))
        .to be_empty
    end
  end

  describe "assigning an value and getting a hash" do
    it "works for [value]=" do
      instance.some_value = "string"

      expect(instance.to_h)
        .to eql("some_value" => "string")
    end

    it "works for [value]_id=" do
      instance.some_value_id = 5

      expect(instance.to_h)
        .to eql("some_value_id" => 5)
    end

    it "works for group_by=" do
      instance.group_by = 8

      expect(instance.to_h)
        .to eql("group_by" => 8)
    end
  end

  describe "assigning an value and getting by hash key" do
    it "works for [value]=" do
      instance.some_value = "string"

      expect(instance[:some_value])
        .to eq("string")
    end

    it "works for [value]_id=" do
      instance.some_value_id = 5

      expect(instance[:some_value_id])
        .to eq(5)
    end

    it "works for group_by=" do
      instance.group_by = 8

      expect(instance[:group_by])
        .to eq(8)
    end
  end

  describe "instantiating with a hash and fetching the value" do
    let(:instance) do
      described_class
        .new({ "some_value" => "string", "some_value_id" => 5, "group_by" => 8 })
    end

    it "allows fetching the value" do
      expect(instance.to_h)
        .to eql({ "some_value" => "string", "some_value_id" => 5, "group_by" => 8 })
    end
  end
end
