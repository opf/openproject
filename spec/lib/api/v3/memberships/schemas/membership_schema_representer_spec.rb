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

describe ::API::V3::Memberships::Schemas::MembershipSchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryBot.build_stubbed(:user) }

  let(:self_link) { '/a/self/link' }
  let(:embedded) { true }
  let(:new_record) { true }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:principal) { FactoryBot.build_stubbed(:group) }
  let(:assigned_project) { nil }
  let(:assigned_principal) { nil }
  let(:allowed_roles) do
    if new_record
      [FactoryBot.build_stubbed(:role),
       FactoryBot.build_stubbed(:role)]
    end
  end

  let(:contract) do
    contract = double('contract',
                      new_record?: new_record,
                      project: assigned_project,
                      principal: assigned_principal)

    allow(contract)
      .to receive(:writable?) do |attribute|
      writable = %w(roles)

      if new_record
        writable = writable.concat(%w(project principal))
      end

      writable.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:assignable_values)
      .with(:roles, current_user)
      .and_return(allowed_roles)

    contract
  end
  let(:representer) do
    described_class.create(contract,
                           self_link,
                           form_embedded: embedded,
                           current_user: current_user)
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe '_type' do
      it 'is indicated as Schema' do
        is_expected.to be_json_eql('Schema'.to_json).at_path('_type')
      end
    end

    describe 'id' do
      let(:path) { 'id' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'Integer' }
        let(:name) { I18n.t('attributes.id') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'createdAt' do
      let(:path) { 'createdAt' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'DateTime' }
        let(:name) { Version.human_attribute_name('created_at') }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe 'project' do
      let(:path) { 'project' }

      context 'if having a new record' do
        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Project' }
          let(:name) { Member.human_attribute_name('project') }
          let(:required) { true }
          let(:writable) { true }
        end

        context 'if embedding' do
          let(:embedded) { true }

          context 'if having no principal' do
            it_behaves_like 'links to allowed values via collection link' do
              let(:href) do
                api_v3_paths.memberships_available_projects
              end
            end
          end

          context 'if having a principal' do
            let(:assigned_principal) { principal }

            it_behaves_like 'links to allowed values via collection link' do
              let(:href) do
                filters = [{ 'principal' => { 'operator' => '!', 'values' => [principal.id.to_s] } }]

                api_v3_paths.path_for(:memberships_available_projects, filters: filters)
              end
            end
          end
        end

        context 'if not embedding' do
          let(:embedded) { false }

          it_behaves_like 'does not link to allowed values'
        end
      end

      context 'if having a persisted record' do
        let(:new_record) { false }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Project' }
          let(:name) { Version.human_attribute_name('project') }
          let(:required) { true }
          let(:writable) { false }
        end

        context 'if embedding' do
          let(:embedded) { true }

          it_behaves_like 'does not link to allowed values'
        end
      end
    end

    describe 'principal' do
      let(:path) { 'principal' }

      context 'if having a new record' do
        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Principal' }
          let(:name) { Version.human_attribute_name('principal') }
          let(:required) { true }
          let(:writable) { true }
        end

        context 'if embedding' do
          let(:embedded) { true }

          context 'if having no project' do
            it_behaves_like 'links to allowed values via collection link' do
              let(:href) do
                statuses = [Principal::STATUSES[:locked].to_s]
                filters = [{ 'status' => { 'operator' => '!', 'values' => statuses } }]

                api_v3_paths.path_for(:principals, filters: filters)
              end
            end
          end

          context 'if having a project' do
            let(:assigned_project) { project }

            it_behaves_like 'links to allowed values via collection link' do
              let(:href) do
                statuses = [Principal::STATUSES[:locked].to_s]
                status_filter = { 'status' => { 'operator' => '!', 'values' => statuses } }
                member_filter = { 'member' => { 'operator' => '!', 'values' => [assigned_project.id.to_s] } }

                filters = [status_filter, member_filter]

                api_v3_paths.path_for(:principals, filters: filters)
              end
            end
          end
        end

        context 'if not embedding' do
          let(:embedded) { false }

          it_behaves_like 'does not link to allowed values'
        end
      end

      context 'if having a persisted record' do
        let(:new_record) { false }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'Principal' }
          let(:name) { Version.human_attribute_name('principal') }
          let(:required) { true }
          let(:writable) { false }
        end

        context 'if embedding' do
          let(:embedded) { true }

          it_behaves_like 'does not link to allowed values'
        end
      end
    end

    describe 'roles' do
      let(:path) { 'roles' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { '[]Role' }
        let(:name) { Version.human_attribute_name('role') }
        let(:required) { true }
        let(:writable) { true }
      end

      context 'if embedding' do
        let(:embedded) { true }

        it_behaves_like 'links to allowed values via collection link' do
          let(:href) do
            api_v3_paths.path_for(:roles, filters: [{ unit: { operator: '=', values: ['project'] } }])
          end
        end
      end

      context 'if not embedding' do
        let(:embedded) { false }

        it_behaves_like 'does not link to allowed values'
      end
    end

    context '_links' do
      describe 'self link' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'self' }
          let(:href) { self_link }
        end

        context 'embedded in a form' do
          let(:self_link) { nil }

          it_behaves_like 'has no link' do
            let(:link) { 'self' }
          end
        end
      end
    end
  end
end
