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
require 'rack/test'

describe 'API v3 Help texts resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:current_user) do
    FactoryBot.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end

  let!(:help_texts) do
    # need to clear the cache to free the memoized
    # Type.translated_work_package_form_attributes
    Rails.cache.clear

    custom_field = FactoryBot.create :text_wp_custom_field

    [
      FactoryBot.create(:work_package_help_text, attribute_name: 'assignee'),
      FactoryBot.create(:work_package_help_text, attribute_name: 'status'),
      FactoryBot.create(:work_package_help_text, attribute_name: "custom_field_#{custom_field.id}")
    ]
  end

  describe 'help_texts' do
    describe '#get' do
      let(:get_path) { api_v3_paths.help_texts }
      subject(:response) { last_response }

      context 'logged in user' do
        before do
          login_as(current_user)

          get get_path
        end

        it_behaves_like 'API V3 collection response', 2, 2, 'HelpText'
      end
    end
  end

  describe 'help_texts/:id' do
    describe '#get' do
      let(:help_text) { help_texts.first }
      let(:get_path) { api_v3_paths.help_text help_text.id }

      subject(:response) { last_response }

      context 'logged in user' do
        before do
          login_as(current_user)

          get get_path
        end

        context 'valid type id' do
          it { expect(response.status).to eq(200) }
        end

        context 'invalid type id' do
          let(:get_path) { api_v3_paths.type 'bogus' }

          it_behaves_like 'param validation error' do
            let(:id) { 'bogus' }
            let(:type) { 'HelpText' }
          end
        end

        context 'invisible type id' do
          # cf not visible to the user
          let(:help_text) { help_texts.last }

          it_behaves_like 'not found' do
            let(:id) { help_text.id }
            let(:type) { 'HelpText' }
          end
        end
      end
    end
  end
end
