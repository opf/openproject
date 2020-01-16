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

require 'spec_helper'

require_relative './shared_model'

describe Grids::MyPage, type: :model do
  let(:instance) { described_class.new(row_count: 5, column_count: 5) }
  let(:user) { FactoryBot.build_stubbed(:user) }

  it_behaves_like 'grid attributes'

  context 'attributes' do
    it '#user' do
      instance.user = user
      expect(instance.user)
        .to eql user
    end
  end

  context 'altering widgets' do
    context 'when removing a work_packages_table widget' do
      let(:user) { FactoryBot.create(:user) }
      let(:query) do
        FactoryBot.create(:query,
                          user: user,
                          hidden: true)
      end

      before do
        widget = Grids::Widget.new(identifier: 'work_packages_table',
                                   start_row: 1,
                                   end_row: 2,
                                   start_column: 1,
                                   end_column: 2,
                                   options: { queryId: query.id })

        instance.widgets = [widget]
        instance.save!
      end

      it 'removes the widget\'s query' do
        instance.widgets = []

        expect(Query.find_by(id: query.id))
          .to be_nil
      end
    end
  end
end
