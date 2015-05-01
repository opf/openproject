#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/v2/statuses/show.api.rabl', type: :view do

  before do
    params[:format] = 'json'
  end

  describe 'with an assigned status' do
    let(:status) {
      FactoryGirl.build(:status,
                        id: 1,
                        name: 'Almost Done',
                        position: 100,
                        default_done_ratio: 90,
                        is_closed: false,
                        is_default: true)
    }

    before do
      assign(:status, status)
      render
    end

    it 'renders a status node' do
      expect(response).to have_json_path('status')
    end

    it 'renders a status-details' do
      expected_json = { name: 'Almost Done', position: 100, is_default: true, is_closed: false, default_done_ratio: 90 }.to_json
      expect(response).to be_json_eql(expected_json).at_path('status')
    end

  end
end
