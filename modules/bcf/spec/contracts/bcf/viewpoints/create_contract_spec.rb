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

describe Bcf::Viewpoints::CreateContract do
  let(:viewpoint) do
    Bcf::Viewpoint.new(uuid: viewpoint_uuid,
                       issue: viewpoint_issue,
                       json_viewpoint: viewpoint_json_viewpoint)
  end
  let(:permissions) { [:manage_bcf] }

  subject(:contract) { described_class.new(viewpoint, current_user) }

  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end
  let!(:allowed_to) do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, permission_project|
      permissions.include?(permission) && project == permission_project
    end
  end
  let(:viewpoint_uuid) { 'issue uuid' }
  let(:viewpoint_json_viewpoint) { 'some json' }
  let(:viewpoint_issue) do
    FactoryBot.build_stubbed(:bcf_issue).tap do |issue|
      allow(issue)
        .to receive(:project)
        .and_return(project)
    end
  end
  let(:project) { FactoryBot.build_stubbed(:project) }

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

  context 'if the issue is nil' do
    let(:viewpoint_issue) { nil }

    it 'is invalid' do
      expect_valid(false, issue: %i(blank))
    end
  end

  context 'if the json_viewpoint is nil' do
    let(:viewpoint_json_viewpoint) { nil }

    it 'is invalid' do
      expect_valid(false, json_viewpoint: %i(blank))
    end
  end

  context 'if the user lacks permission' do
    let(:permissions) { [] }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end
end
