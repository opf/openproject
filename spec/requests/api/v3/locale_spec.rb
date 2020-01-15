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

# This takes the schema endpoint to test localization as there
# are localized strings in the response.

describe 'API localization', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryBot.create(:project) }
  let(:type) { FactoryBot.create(:type) }
  let(:schema_path) { api_v3_paths.work_package_schema project.id, type.id }
  let(:current_user) { FactoryBot.build(:user, member_in_project: project, language: :fr) }

  describe 'GET /api/v3/work_packages/schemas/:id' do
    before do
      allow(User).to receive(:current).and_return(current_user)
    end

    context 'with the user having selected a language' do
      before do
        get schema_path
      end

      it "responds in the user's locale" do
        expected_i18n = WorkPackage.human_attribute_name(:subject,
                                                         locale: current_user.language).to_json

        expect(last_response.body).to be_json_eql(expected_i18n).at_path('subject/name')
      end
    end

    context 'when sending a header and not having a language selected' do
      before do
        current_user.language = nil

        header 'ACCEPT_LANGUAGE', 'de,en-US;q=0.8,en;q=0.6'
        get schema_path
      end

      it "responds in the user's locale" do
        expected_i18n = WorkPackage.human_attribute_name(:subject, locale: 'de').to_json

        expect(last_response.body).to be_json_eql(expected_i18n).at_path('subject/name')
      end
    end
  end
end
