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

describe ::API::V3::Budgets::BudgetRepresenter do
  let(:project) { FactoryBot.build(:project, id: 999) }
  let(:user) {
    FactoryBot.build(:user,
                      member_in_project: project,
                      created_on: 1.day.ago,
                      updated_on: Date.today)
  }
  let(:budget) {
    FactoryBot.create(:cost_object,
                       author: user,
                       project: project,
                       created_on: 1.day.ago,
                       updated_on: Date.today)
  }

  let(:representer)  { described_class.new(budget, current_user: user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe 'self link' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { "/api/v3/budgets/#{budget.id}" }
        let(:title) { budget.subject }
      end
    end

    it 'indicates its type' do
      is_expected.to be_json_eql('Budget'.to_json).at_path('_type')
    end

    it 'indicates its id' do
      is_expected.to be_json_eql(budget.id.to_json).at_path('id')
    end

    it 'indicates its subject' do
      is_expected.to be_json_eql(budget.subject.to_json).at_path('subject')
    end
  end
end
