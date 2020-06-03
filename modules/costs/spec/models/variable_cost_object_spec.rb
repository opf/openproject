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

require File.dirname(__FILE__) + '/../spec_helper'

describe VariableCostObject, type: :model do
  let(:cost_object) { FactoryBot.build(:variable_cost_object, project: project) }
  let(:type) { FactoryBot.create(:type_feature) }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:user) { FactoryBot.create(:user) }

  describe 'initialization' do
    let(:cost_object) { VariableCostObject.new }

    before do
      allow(User).to receive(:current).and_return(user)
    end

    it { expect(cost_object.author).to eq(user) }
  end

  describe 'destroy' do
    let(:work_package) { FactoryBot.create(:work_package, project: project) }

    before do
      cost_object.author = user
      cost_object.work_packages = [work_package]
      cost_object.save!

      cost_object.destroy
    end

    it { expect(VariableCostObject.find_by_id(cost_object.id)).to be_nil }
    it { expect(WorkPackage.find_by_id(work_package.id)).to eq(work_package) }
    it { expect(work_package.reload.cost_object).to be_nil }
  end
end
