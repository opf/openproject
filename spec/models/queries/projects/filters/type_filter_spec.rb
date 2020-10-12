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

require 'spec_helper'

describe Queries::Projects::Filters::TypeFilter, type: :model do
  it_behaves_like 'basic query filter' do
    let(:class_key) { :type_id }
    let(:type) { :list }
    let(:model) { Project }
    let(:attribute) { :type_id }
    let(:values) { ['3'] }
    let(:admin) { FactoryBot.build_stubbed(:admin) }
    let(:user) { FactoryBot.build_stubbed(:user) }

    before do
      allow(Type).to receive(:pluck).with(:name, :id).and_return([['Foo', '1234']])
    end

    describe '#allowed_values' do
      it 'is a list of the possible values' do
        expect(instance.allowed_values).to match_array([['Foo', '1234']])
      end
    end
  end
end
