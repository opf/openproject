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

describe Grids::Query, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let!(:my_page_grid) do
    FactoryBot.create(:my_page, user: user)
  end
  let!(:other_my_page_grid) do
    FactoryBot.create(:my_page, user: other_user)
  end
  let(:instance) { described_class.new }

  before do
    login_as(user)
  end

  context 'without a filter' do
    describe '#results' do
      it 'is the same as getting all the grids visible to the user' do
        expect(instance.results).to match_array [my_page_grid]
      end
    end
  end

  context 'with a scope filter' do
    before do
      instance.where('scope', '=', ['/my/page'])
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        expect(instance.results).to match_array [my_page_grid]
      end
    end

    describe '#valid?' do
      it 'is true' do
        expect(instance).to be_valid
      end

      it 'is invalid if the filter is invalid' do
        instance.where('scope', '!', ['/some/other/page'])
        expect(instance).to be_invalid
      end
    end
  end
end
