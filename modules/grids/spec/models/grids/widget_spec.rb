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

RSpec.describe Grids::Widget do
  let(:instance) { Grids::Widget.new }

  describe "attributes" do
    it "#start_row" do
      instance.start_row = 5
      expect(instance.start_row)
        .to be 5
    end

    it "#end_row" do
      instance.end_row = 5
      expect(instance.end_row)
        .to be 5
    end

    it "#start_column" do
      instance.start_column = 5
      expect(instance.start_column)
        .to be 5
    end

    it "#end_column" do
      instance.end_column = 5
      expect(instance.end_column)
        .to be 5
    end

    it "#identifier" do
      instance.identifier = "some_identifier"
      expect(instance.identifier)
        .to eql "some_identifier"
    end

    it "#options" do
      value = {
        some: "value",
        and: {
          also: 1
        }
      }

      instance.options = value
      expect(instance.options)
        .to eql value
    end

    it "#grid" do
      grid = Grids::Grid.new
      instance.grid = grid
      expect(instance.grid)
        .to eql grid
    end
  end
end
