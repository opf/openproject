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

describe 'API v3 Work package resource' do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers

  let(:current_user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:work_package) {
    FactoryBot.create(:work_package,
                       project: project,
                       story_points: 8,
                       remaining_hours: 5)
  }
  let(:wp_path) { "/api/v3/work_packages/#{work_package.id}" }

  before do
    allow(Story).to receive(:types).and_return([work_package.type_id])
  end

  describe '#get' do
    shared_context 'query work package' do
      before do
        allow(User).to receive(:current).and_return(current_user)
        get wp_path
      end

      subject { last_response.body }
    end

    context 'backlogs activated' do
      include_context 'query work package'

      it { is_expected.to be_json_eql(work_package.story_points.to_json).at_path('storyPoints') }

      it { is_expected.to be_json_eql('PT5H'.to_json).at_path('remainingTime') }
    end

    context 'backlogs deactivated' do
      let(:project) {
        FactoryBot.create(:project, disable_modules: 'backlogs')
      }

      include_context 'query work package'

      it { expect(last_response.status).to eql 200 }

      it { is_expected.not_to have_json_path('storyPoints') }

      it { is_expected.not_to have_json_path('remainingTime') }
    end
  end

  describe '#patch' do
    let(:valid_params) do
      {
        _type: 'WorkPackage',
        lockVersion: work_package.lock_version
      }
    end

    subject { last_response }

    before do
      allow(User).to receive(:current).and_return current_user
      patch wp_path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    describe 'storyPoints' do
      let(:params) { valid_params.merge(storyPoints: 12) }

      it { expect(subject.status).to eq(200) }
      it { expect(subject.body).to be_json_eql(12.to_json).at_path('storyPoints') }
    end

    describe 'remainingTime' do
      let(:params) { valid_params.merge(remainingTime: 'PT12H30M') }

      it { expect(subject.status).to eq(200) }
      it { expect(subject.body).to be_json_eql('PT12H30M'.to_json).at_path('remainingTime') }
    end
  end
end
