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

describe Queries::WorkPackages::Filter::SubjectOrIdFilter, type: :model do
  let(:value) { 'bogus' }
  let(:operator) { '**' }
  let(:subject) { 'Some subject' }
  let(:work_package) { FactoryBot.create(:work_package, subject: subject) }
  let(:current_user) { FactoryBot.build(:user, member_in_project: work_package.project) }
  let(:query) { FactoryBot.build_stubbed(:global_query, user: current_user) }
  let(:instance) do
    described_class.create!(name: :search, context: query, operator: operator, values: [value])
  end

  before do
    login_as current_user
  end

  it 'finds in subject' do
    instance.values = ['Some subject']
    expect(WorkPackage.eager_load(instance.includes).where(instance.where))
      .to match_array [work_package]
  end

  it 'finds in ID' do
    instance.values = [work_package.id.to_s]
    expect(WorkPackage.eager_load(instance.includes).where(instance.where))
      .to match_array [work_package]
  end
end
