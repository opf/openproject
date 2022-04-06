#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe ::API::V3::Queries::QueryRepresenter, 'parsing' do
  include ::API::V3::Utilities::PathHelper

  let(:query) { ::API::ParserStruct.new }
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:representer) do
    described_class.new(query, current_user: current_user, embed_links: true)
  end

  let(:permissions) { [] }

  let(:policy) do
    policy_stub = instance_double(QueryPolicy)

    allow(QueryPolicy)
      .to receive(:new)
      .with(current_user)
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

  current_user { build_stubbed(:user) }

  before do
    policy
  end

  subject { representer.from_hash request_body }

  describe 'empty group_by (Regression #25606)' do
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

    it 'unsets group_by' do
      expect(query.group_by).to eq('project')
    end
  end

  describe 'highlighted_attributes', with_ee: [:conditional_highlighting] do
    let(:request_body) do
      {
        '_links' => {
          'highlightedAttributes' => [{ 'href' => "/api/v3/queries/columns/type" }]
        }
      }
    end

    it 'sets highlighted_attributes' do
      expect(subject.highlighted_attributes).to eq(%i{type})
    end
  end

  describe 'ordered work packages' do
    let(:request_body) do
      {
        'orderedWorkPackages' => {
          50 => 0,
          38 => 1234,
          102 => 81234123
        }
      }
    end

    before do
      allow(query).to receive(:persisted?).and_return(persisted)
    end

    context 'if query is new' do
      let(:persisted) { nil }

      it 'sets ordered_work_packages' do
        order = subject.ordered_work_packages
        expect(order).to eq({ '50' => 0, '38' => 1234, '102' => 81234123 })
      end
    end

    context 'if query is not new' do
      let(:persisted) { true }

      it 'sets ordered_work_packages' do
        allow(query)
          .to receive(:ordered_work_packages)

        subject

        expect(query)
          .not_to have_received(:ordered_work_packages)
      end
    end
  end

  describe 'project' do
    let(:query) { build_stubbed(:query, project: nil) }

    let(:request_body) do
      {
        '_links' => {
          'project' => {
            'href' => "/api/v3/projects/#{project_id}"
          }
        }
      }
    end

    before do
      scope = instance_double(ActiveRecord::Relation)

      allow(Project)
        .to receive(:where)
              .with(identifier: project_id)
              .and_return(scope)
      allow(scope)
        .to receive(:pick)
              .with(:id)
              .and_return(project.id)
    end

    context 'for a number only id' do
      let(:project_id) { project.id }

      it 'sets the project_id accordingly' do
        expect(subject.project_id)
          .to eql project.id
      end
    end

    context 'for a text only id (identifier)' do
      let(:project_id) { project.identifier }

      it 'deduces the id for the project_id accordingly' do
        expect(subject.project_id)
          .to eql project.id
      end
    end

    context 'for a text starting with numbers (identifier)' do
      let(:project) { build_stubbed(:project, identifier: '5555-numbered-identifier') }
      let(:project_id) { project.identifier }

      it 'deduces the id for the project_id accordingly' do
        expect(subject.project_id)
          .to eql project.id
      end
    end
  end
end
