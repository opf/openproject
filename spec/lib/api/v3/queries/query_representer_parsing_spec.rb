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

describe ::API::V3::Queries::QueryRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:query) { FactoryBot.build_stubbed(:query, project: project) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:user) { double('current_user') }
  let(:representer) do
    described_class.new(query, current_user: user, embed_links: true)
  end

  let(:permissions) { [] }

  let(:policy) do
    policy_stub = double('policy stub')

    allow(QueryPolicy)
      .to receive(:new)
      .with(user)
      .and_return(policy_stub)

    allow(policy_stub)
      .to receive(:allowed?)
      .and_return(false)

    permissions.each do |permission|
      allow(policy_stub)
        .to receive(:allowed?)
        .with(query, permission)
        .and_return(true)
    end
  end

  before do
    policy
  end

  subject { representer.from_hash request_body }

  describe 'parsing empty group_by (Regression #25606)' do
    before do
      query.group_by = 'project'
    end

    let(:request_body) do
      {
        '_links' => {
          'groupBy' => { 'href' => nil }
        }
      }
    end

    it 'should unset group_by' do
      expect(query).to be_grouped
      expect(query.group_by).to eq('project')

      expect(subject).not_to be_grouped
    end
  end

  describe 'parsing highlighted_attributes', with_ee: [:conditional_highlighting] do
    let(:request_body) do
      {
        '_links' => {
          'highlightedAttributes' => [{ 'href' => "/api/v3/queries/columns/type" }]
        }
      }
    end

    it 'should set highlighted_attributes' do
      expect(subject.highlighted_attributes).to eq(%i{type})
    end
  end
end
