#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

shared_context 'grid contract' do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:instance) { described_class.new(grid, user) }
  let(:widgets) { [] }
  let(:default_values) do
    {
      row_count: 6,
      column_count: 7,
      widgets: widgets
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

  describe 'widgets' do
    before do
      allow(Grids::Configuration)
        .to receive(:writable?)
        .and_return(true)

      allow(Grids::Configuration)
        .to receive(:registered_grid?)
        .with(Grids::Grid)
        .and_return(true)

      allow(Grids::Configuration)
        .to receive(:allowed_widget?)
        .with(Grids::Grid, 'widget1', user, nil)
        .and_return(true)

      allow(Grids::Configuration)
        .to receive(:allowed_widget?)
        .with(Grids::Grid, 'widget2', user, nil)
        .and_return(false)
    end

    context 'if there are new widgets that are not allowed' do
      let(:widgets) do
        [Grids::Widget.new(identifier: 'widget2', start_row: 1, end_row: 3, start_column: 1, end_column: 3)]
      end

      it 'notes the error' do
        instance.validate

        expect(instance.errors.details[:widgets])
          .to match_array [{ error: :inclusion }]
      end
    end

    context 'if there are new widgets that are allowed' do
      let(:widgets) do
        [Grids::Widget.new(identifier: 'widget1', start_row: 1, end_row: 3, start_column: 1, end_column: 3)]
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end

    context 'if there are new widgets that are not allowed but marked for destruction' do
      let(:widgets) do
        widget = Grids::Widget.new(identifier: 'widget2', start_row: 1, end_row: 3, start_column: 1, end_column: 3)

        allow(widget)
          .to receive(:marked_for_destruction?)
          .and_return(true)

        [widget]
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end

    context 'if there are existing widgets that are not allowed' do
      let(:widgets) do
        [FactoryBot.build_stubbed(:grid_widget, identifier: 'widget2', start_row: 1, end_row: 3, start_column: 1, end_column: 3)]
      end

      it 'is valid' do
        expect(instance.validate)
          .to be_truthy
      end
    end
  end
end
