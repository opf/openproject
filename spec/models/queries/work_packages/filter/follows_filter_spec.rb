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

require 'spec_helper'

describe Queries::WorkPackages::Filter::FollowsFilter, type: :model do
  it_behaves_like 'filter by work package id' do
    let(:class_key) { :follower }

    describe '#where' do
      let!(:following_wp) { FactoryBot.create(:work_package, follows: [filter_wp]) }
      let!(:filter_wp) { FactoryBot.create(:work_package) }
      let!(:other_wp) { FactoryBot.create(:work_package) }

      before do
        instance.values = [filter_wp.id.to_s]
      end

      context "on '=' operator" do
        before do
          instance.operator = '='
        end

        it 'returns the preceding work packages' do
          expect(WorkPackage.where(instance.where))
            .to match_array [following_wp]
        end
      end

      context "on '!' operator" do
        before do
          instance.operator = '!'
        end

        it 'returns the not preceding work packages' do
          expect(WorkPackage.where(instance.where))
            .to match_array [filter_wp, other_wp]
        end
      end
    end
  end
end
