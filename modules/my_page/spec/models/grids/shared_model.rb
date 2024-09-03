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

RSpec.shared_examples_for "grid attributes" do
  describe "attributes" do
    it "#row_count" do
      instance.row_count = 5
      expect(instance.row_count)
        .to be 5
    end

    it "#column_count" do
      instance.column_count = 5
      expect(instance.column_count)
        .to be 5
    end

    it "#name" do
      instance.name = "custom 123"
      expect(instance.name)
        .to eql "custom 123"

      # can be empty
      instance.name = nil
      expect(instance).to be_valid
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

    it "#widgets" do
      widgets = [
        Grids::Widget.new(start_row: 2),
        Grids::Widget.new(start_row: 5)
      ]

      instance.widgets = widgets
      expect(instance.widgets)
        .to match_array widgets
    end
  end
end
