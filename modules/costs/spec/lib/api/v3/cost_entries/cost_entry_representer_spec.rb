#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe ::API::V3::CostEntries::CostEntryRepresenter do
  include API::V3::Utilities::PathHelper

  let(:cost_entry) { FactoryBot.build(:cost_entry, id: 42) }
  let(:representer) { described_class.new(cost_entry, current_user: double('current_user')) }

  subject { representer.to_json }

  it 'has a type' do
    is_expected.to be_json_eql('CostEntry'.to_json).at_path('_type')
  end

  it_behaves_like 'has an untitled link' do
    let(:link) { 'self' }
    let(:href) { api_v3_paths.cost_entry cost_entry.id }
  end

  it_behaves_like 'has a titled link' do
    let(:link) { 'project' }
    let(:href) { api_v3_paths.project cost_entry.project.id }
    let(:title) { cost_entry.project.name }
  end

  it_behaves_like 'has a titled link' do
    let(:link) { 'user' }
    let(:href) { api_v3_paths.user cost_entry.user.id }
    let(:title) { cost_entry.user.name }
  end

  it_behaves_like 'has a titled link' do
    let(:link) { 'costType' }
    let(:href) { api_v3_paths.cost_type cost_entry.cost_type.id }
    let(:title) { cost_entry.cost_type.name }
  end

  it_behaves_like 'has a titled link' do
    let(:link) { 'workPackage' }
    let(:href) { api_v3_paths.work_package cost_entry.work_package.id }
    let(:title) { cost_entry.work_package.subject }
  end

  it 'has an id' do
    is_expected.to be_json_eql(cost_entry.id.to_json).at_path('id')
  end

  it 'has spent units' do
    is_expected.to be_json_eql(cost_entry.units.to_json).at_path('spentUnits')
  end

  it_behaves_like 'has ISO 8601 date only' do
    let(:date) { cost_entry.spent_on }
    let(:json_path) { 'spentOn' }
  end

  it_behaves_like 'has UTC ISO 8601 date and time' do
    let(:date) { cost_entry.created_on }
    let(:json_path) { 'createdAt' }
  end

  it_behaves_like 'has UTC ISO 8601 date and time' do
    let(:date) { cost_entry.updated_on }
    let(:json_path) { 'updatedAt' }
  end
end
