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

describe ::API::V3::Budgets::BudgetRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.build(:project, id: 999) }
  let(:user) do
    FactoryBot.build(:user,
                     member_in_project: project,
                     created_on: 1.day.ago,
                     updated_on: Date.today)
  end
  let(:budget) do
    FactoryBot.create(:cost_object,
                      author: user,
                      project: project,
                      created_on: 1.day.ago,
                      updated_on: Date.today)
  end

  let(:representer) { described_class.new(budget, current_user: user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe 'self link' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.budget(budget.id) }
        let(:title) { budget.subject }
      end
    end

    it_behaves_like 'has an untitled link' do
      let(:link) { :attachments }
      let(:href) { api_v3_paths.attachments_by_budget budget.id }
    end

    it_behaves_like 'has an untitled action link' do
      let(:link) { :addAttachment }
      let(:href) { api_v3_paths.attachments_by_budget budget.id }
      let(:method) { :post }
      let(:permission) { :edit_cost_objects }
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
