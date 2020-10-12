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
require_relative '../shared_expectations'

describe CustomActions::Actions::Date, type: :model do
  let(:key) { :date }
  let(:type) { :date_property }
  let(:value) { Date.today }

  it_behaves_like 'base custom action' do
    describe '#apply' do
      let(:work_package) { FactoryBot.build_stubbed(:stubbed_work_package) }

      it 'sets both start and finish date to the action\'s value' do
        instance.values = [Date.today + 5]

        instance.apply(work_package)

        expect(work_package.start_date)
          .to eql Date.today + 5
        expect(work_package.due_date)
          .to eql Date.today + 5
      end

      it 'sets both start and finish date to the current date if so specified' do
        instance.values = ['%CURRENT_DATE%']

        instance.apply(work_package)

        expect(work_package.start_date)
          .to eql Date.today
        expect(work_package.due_date)
          .to eql Date.today
      end
    end

    describe '#multi_value?' do
      it 'is false' do
        expect(instance)
          .not_to be_multi_value
      end
    end
  end
end
