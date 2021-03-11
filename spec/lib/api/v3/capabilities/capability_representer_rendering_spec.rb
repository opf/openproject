#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Capabilities::CapabilityRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  subject { representer.to_json }

  let(:capability) do
    OpenStruct.new(id: id, principal: principal, principal_id: principal.id, context: context, context_id: context&.id)
  end
  let(:context) { FactoryBot.build_stubbed(:project) }
  let(:principal) { user }
  let(:id) { 'users/create' }

  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:group) { FactoryBot.build_stubbed(:group) }
  let(:placeholder_user) { FactoryBot.build_stubbed(:placeholder_user) }

  let(:current_user) { FactoryBot.build_stubbed(:user) }

  let(:representer) do
    described_class
      .create(capability,
              current_user: current_user,
              embed_links: true)
  end

  describe '_links' do
    describe 'self' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.capability capability.id }
      end
    end

    describe 'context' do
      context 'for a project' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'context' }
          let(:href) { api_v3_paths.project(context.id) }
          let(:title) { context.name }
        end
      end

      context 'when global' do
        let(:context) { nil }

        it_behaves_like 'has an untitled link' do
          let(:link) { 'context' }
          let(:href) { api_v3_paths.capabilities_contexts_global }
        end
      end
    end
  end

  describe 'principal' do
    context 'for a user principal' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'principal' }
        let(:href) { api_v3_paths.user(user.id) }
        let(:title) { user.name }
      end
    end

    context 'for a group principal' do
      let(:principal) { group }

      it_behaves_like 'has a titled link' do
        let(:link) { 'principal' }
        let(:href) { api_v3_paths.group(group.id) }
        let(:title) { group.name }
      end
    end

    context 'for a placeholder user principal' do
      let(:principal) { placeholder_user }

      it_behaves_like 'has a titled link' do
        let(:link) { 'principal' }
        let(:href) { api_v3_paths.placeholder_user(placeholder_user.id) }
        let(:title) { placeholder_user.name }
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Capability' }
    end

    it_behaves_like 'property', :id do
      let(:value) { capability.id }
    end
  end

  describe '_embedded' do
    describe 'context' do
      let(:embedded_path) { '_embedded/context' }

      context 'for a project' do
        it 'has the project embedded' do
          is_expected
            .to be_json_eql('Project'.to_json)
            .at_path("#{embedded_path}/_type")

          is_expected
            .to be_json_eql(context.name.to_json)
            .at_path("#{embedded_path}/name")
        end
      end
    end
  end

  describe 'principal' do
    let(:embedded_path) { '_embedded/principal' }

    context 'for a user principal' do
      it 'has the user embedded' do
        is_expected
          .to be_json_eql('User'.to_json)
          .at_path("#{embedded_path}/_type")

        is_expected
          .to be_json_eql(user.name.to_json)
          .at_path("#{embedded_path}/name")
      end
    end

    context 'for a group principal' do
      let(:principal) { group }

      it 'has the group embedded' do
        is_expected
          .to be_json_eql('Group'.to_json)
          .at_path("#{embedded_path}/_type")

        is_expected
          .to be_json_eql(group.name.to_json)
          .at_path("#{embedded_path}/name")
      end
    end

    context 'for a placeholder user principal' do
      let(:principal) { placeholder_user }

      it 'has the group embedded' do
        is_expected
          .to be_json_eql('PlaceholderUser'.to_json)
          .at_path("#{embedded_path}/_type")

        is_expected
          .to be_json_eql(placeholder_user.name.to_json)
          .at_path("#{embedded_path}/name")
      end
    end
  end
end
