#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource' do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers

  let(:admin) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) { FactoryGirl.create(:work_package,
                                          project: project,
                                          story_points: 8,
                                          remaining_hours: 5) }

  describe '#get' do
    shared_context 'query work package' do
      before do
        allow(User).to receive(:current).and_return(admin)
        get "/api/v3/work_packages/#{work_package.id}"
      end

      subject(:parsed_response) { JSON.parse(last_response.body) }
    end

    context 'backlogs activated' do
      include_context 'query work package'

      it { expect(parsed_response['storyPoints']).to eq(work_package.story_points) }

      it { expect(parsed_response['remainingHours']).to eq(work_package.remaining_hours) }
    end

    context 'backlogs deactivated' do
      let(:project) { FactoryGirl.create(:project,
                                         enabled_module_names: []) }

      include_context 'query work package'

      it { expect(parsed_response['storyPoints']).to be_nil }

      it { expect(parsed_response['remainingHours']).to be_nil }
    end
  end
end
