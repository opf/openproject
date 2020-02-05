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

shared_examples_for 'issues contract' do
  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end
  let!(:allowed_to) do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, permission_project|
      permissions.include?(permission) && project == permission_project
    end
  end
  let(:issue_uuid) { 'issue uuid' }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:issue_work_package) { FactoryBot.build_stubbed(:stubbed_work_package, project: project) }
  let(:issue_work_package_id) do
    id = 5

    allow(WorkPackage)
      .to receive(:find)
      .with(id)
      .and_return(issue_work_package)

    id
  end
  let(:issue_index) { 8 }

  before do
    allow(issue)
      .to receive(:project)
      .and_return(project)
  end

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples 'is valid' do
    it 'is valid' do
      expect_valid(true)
    end
  end

  it_behaves_like 'is valid'

  context 'if the uuid is nil' do
    let(:issue_uuid) { nil }

    it_behaves_like 'is valid' # as the uuid will be set
  end

  context 'if the work_package_id is nil' do
    let(:issue_work_package) { nil }

    it 'is invalid' do
      expect_valid(false, work_package: %i(blank))
    end
  end

  context 'if the user lacks permission' do
    let(:permissions) { [] }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  context 'if the stage is written' do
    before do
      issue.stage = 'some stage'
    end

    it 'is invalid' do
      expect_valid(false, stage: %i(error_readonly))
    end
  end

  context 'if labels is written' do
    before do
      issue.labels = %w(some labels)
    end

    it 'is invalid' do
      expect_valid(false, labels: %i(error_readonly))
    end
  end

  context 'if index is nil' do
    let(:issue_index) { nil }

    it_behaves_like 'is valid'
  end
end
