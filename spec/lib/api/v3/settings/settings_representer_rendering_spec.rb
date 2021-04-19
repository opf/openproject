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

describe ::API::V3::Settings::SettingsRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper
  subject { representer.to_json }

  let(:representer) do
    described_class.create(Setting.all, current_user: current_user, embed_links: true)
  end

  let(:current_user) { FactoryBot.build_stubbed(:user) }

  #let(:setting_name) { 'some_setting' }
  #let(:setting_updated_at) { DateTime.now }
  #let(:setting_config) do
  #  {
  #    setting_name => {
  #      'serialized' => false,
  #      'format' => 'boolean'
  #    }
  #  }
  #end
  #let(:setting) { instance_double('Setting', name: setting_name, value: true, updated_at: setting_updated_at) }
  #let(:settings) do
  #  [setting]
  #end

  #before do
  #  allow(Setting)
  #    .to receive(:available_settings)
  #    .and_return(setting_config)
  #end

  #before do
  #  allow(current_user)
  #    .to receive(:allowed_to?) do |permission, context_project|
  #    project == context_project && permissions.include?(permission)
  #  end
  #end

  describe '_links' do
    describe 'self' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.settings }
        let(:title) { I18n.t(:label_setting_plural) }
      end
    end

  #  describe 'schema' do
  #    it_behaves_like 'has an untitled link' do
  #      let(:link) { 'schema' }
  #      let(:href) { api_v3_paths.membership_schema }
  #    end
  #  end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Settings' }
    end

    context 'with a boolean setting' do
      it_behaves_like 'property', :someSetting do
        let(:value) { setting.value }
      end
    end

    describe 'updatedAt' do
      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { setting_updated_at }
        let(:json_path) { 'updatedAt' }
      end
    end
  end

  #describe '_embedded' do
  #  describe 'project' do
  #    let(:embedded_path) { '_embedded/project' }

  #    it 'has the project embedded' do
  #      is_expected
  #        .to be_json_eql('Project'.to_json)
  #              .at_path("#{embedded_path}/_type")

  #      is_expected
  #        .to be_json_eql(project.name.to_json)
  #              .at_path("#{embedded_path}/name")
  #    end

  #    context 'for a global member' do
  #      let(:project) { nil }

  #      it 'has no project embedded' do
  #        is_expected
  #          .not_to have_json_path(embedded_path)
  #      end
  #    end
  #  end

  #  describe 'principal' do
  #    let(:embedded_path) { '_embedded/principal' }

  #    context 'for a user principal' do
  #      it 'has the user embedded' do
  #        is_expected
  #          .to be_json_eql('User'.to_json)
  #                .at_path("#{embedded_path}/_type")

  #        is_expected
  #          .to be_json_eql(user.name.to_json)
  #                .at_path("#{embedded_path}/name")
  #      end
  #    end

  #    context 'for a group principal' do
  #      let(:principal) { group }

  #      it 'has the group embedded' do
  #        is_expected
  #          .to be_json_eql('Group'.to_json)
  #                .at_path("#{embedded_path}/_type")

  #        is_expected
  #          .to be_json_eql(group.name.to_json)
  #                .at_path("#{embedded_path}/name")
  #      end
  #    end
  #  end

  #  describe 'roles' do
  #    let(:embedded_path) { '_embedded/roles' }

  #    it 'has an array of roles embedded that excludes member_roles marked for destruction' do
  #      is_expected
  #        .to be_json_eql('Role'.to_json)
  #              .at_path("#{embedded_path}/0/_type")

  #      is_expected
  #        .to be_json_eql(role1.name.to_json)
  #              .at_path("#{embedded_path}/0/name")

  #      is_expected
  #        .to be_json_eql('Role'.to_json)
  #              .at_path("#{embedded_path}/1/_type")

  #      is_expected
  #        .to be_json_eql(role2.name.to_json)
  #              .at_path("#{embedded_path}/1/name")
  #    end
  #  end
  #end
end
