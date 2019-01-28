#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

shared_examples_for 'grid attributes' do
  describe 'attributes' do
    it '#row_count' do
      instance.row_count = 5
      expect(instance.row_count)
        .to eql 5
    end

    it '#column_count' do
      instance.column_count = 5
      expect(instance.column_count)
        .to eql 5
    end

    it '#widgets' do
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
