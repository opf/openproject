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

describe Queries::CreateService do
  let(:user) { FactoryBot.build_stubbed(:admin) }
  let(:query) { FactoryBot.build(:query, user: user) }

  let(:instance) { described_class.new(user: user) }
  subject { instance.call(query).result }

  describe 'ordered work packages' do
    let!(:work_package) { FactoryBot.create :work_package }

    before do
      query.ordered_work_packages.build(work_package_id: work_package.id, position: 0)
      query.ordered_work_packages.build(work_package_id: 99999, position: 1)
    end

    it 'removes items for which work packages do not exist' do
      expect(subject).to be_valid
      expect(subject.ordered_work_packages.length).to eq 1
      expect(subject.ordered_work_packages.first.work_package_id).to eq work_package.id
    end
  end
end
