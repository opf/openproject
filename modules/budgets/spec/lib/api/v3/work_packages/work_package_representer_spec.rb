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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:role) do
    FactoryBot.create(:role, permissions: [:view_time_entries,
                                           :view_cost_entries,
                                           :view_cost_rates,
                                           :view_work_packages])
  end
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end

  let(:cost_object) { FactoryBot.create(:cost_object, project: project) }
  let(:cost_entry_1) do
    FactoryBot.create(:cost_entry,
                      work_package: work_package,
                      project: project,
                      units: 3,
                      spent_on: Date.today,
                      user: user,
                      comments: 'Entry 1')
  end
  let(:cost_entry_2) do
    FactoryBot.create(:cost_entry,
                      work_package: work_package,
                      project: project,
                      units: 3,
                      spent_on: Date.today,
                      user: user,
                      comments: 'Entry 2')
  end

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id,
                      cost_object: cost_object)
  end
  let(:representer) do
    described_class.new(work_package,
                        current_user: user,
                        embed_links: true)
  end

  before(:each) do
    allow(User).to receive(:current).and_return user
  end

  subject(:generated) { representer.to_json }

  describe 'generation' do
    before do
      cost_entry_1
      cost_entry_2
    end

    describe 'work_package' do
      describe 'budget' do
        before do
          allow(representer)
            .to receive(:cost_object_visible?)
            .and_return(true)
        end

        it_behaves_like 'has a titled link' do
          let(:link) { 'costObject' }
          let(:href) { "/api/v3/budgets/#{cost_object.id}" }
          let(:title) { cost_object.subject }
        end

        it 'has the budget embedded' do
          is_expected.to be_json_eql(cost_object.subject.to_json)
                           .at_path('_embedded/costObject/subject')
        end
      end
    end
  end

  describe 'costs module disabled' do
    before do
      allow(work_package)
        .to receive(:module_enabled?)
        .with(:budgets)
        .and_return false
    end

    describe 'work_package' do
      describe 'embedded' do
        it { is_expected.not_to have_json_path('_embedded/costObject') }
      end
    end
  end

  describe '.to_eager_load' do
    it 'includes the cost objects' do
      expect(described_class.to_eager_load.any? do |el|
        el == :cost_object
      end).to be_truthy
    end
  end
end
