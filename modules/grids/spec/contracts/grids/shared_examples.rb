#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

shared_context 'grid contract' do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:instance) { described_class.new(grid, user) }
  let(:default_values) do
    {
      row_count: 6,
      column_count: 7,
      widgets: []
    }
  end
  let(:grid) do
    FactoryBot.build_stubbed(:grid, default_values)
  end

  shared_examples_for 'validates positive integer' do
    context 'when the value is negative' do
      let(:value) { -1 }

      it 'is invalid' do
        instance.validate

        expect(instance.errors.details[attribute])
          .to match_array [{ error: :greater_than, count: 0 }]
      end
    end

    context 'when the value is nil' do
      let(:value) { nil }

      it 'is invalid' do
        instance.validate

        expect(instance.errors.details[attribute])
          .to match_array [{ error: :blank }]
      end
    end
  end
end

shared_examples_for 'shared grid contract attributes' do
  include_context 'model contract'
  let(:model) { grid }

  describe 'row_count' do
    it_behaves_like 'is writable' do
      let(:attribute) { :row_count }
      let(:value) { 5 }

      it_behaves_like 'validates positive integer'
    end

    context 'row_count less than 1' do
      before do
        grid.row_count = 0
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:row_count])
          .to match_array [{ error: :greater_than, count: 0 }]
      end
    end
  end

  describe 'column_count' do
    it_behaves_like 'is writable' do
      let(:attribute) { :column_count }
      let(:value) { 5 }

      it_behaves_like 'validates positive integer'
    end

    context 'row_count less than 1' do
      before do
        grid.column_count = 0
      end

      it 'notes the error' do
        instance.validate
        expect(instance.errors.details[:column_count])
          .to match_array [{ error: :greater_than, count: 0 }]
      end
    end
  end

  describe 'valid grid subclasses' do
    context 'for the Grid superclass itself' do
      let(:grid) do
        FactoryBot.build_stubbed(:grid, default_values)
      end

      before do
        instance.validate
      end

      it 'is invalid for the grid superclass itself' do
        expect(instance.errors.details[:scope])
          .to match_array [{ error: :inclusion }]
      end
    end
  end
end
