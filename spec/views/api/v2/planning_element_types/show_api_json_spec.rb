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

describe 'api/v2/planning_element_types/show.api.rabl', type: :view do

  before do
    params[:format] = 'json'
  end

  describe 'with an assigned planning element type' do
    let(:planning_element_type) do
      FactoryGirl.build(:type,
                        id: 1,
                        name: 'Awesometastic Planning Element Type',

                        in_aggregation: false,
                        is_milestone: true,
                        is_default: true,

                        position: 100,

                        created_at: Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                        updated_at: Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    end

    before do
      assign(:type, planning_element_type)
      render
    end

    subject { response.body }

    it 'renders a planning_element_type document' do
      is_expected.to have_json_path('planning_element_type')
    end

    it 'should render all detail-information for the planning-element-type' do
      expected_json =  { name: 'Awesometastic Planning Element Type',

                         in_aggregation: false,
                         is_milestone: true,
                         is_default: true,

                         position: 100,
      }.to_json

      is_expected.to be_json_eql(expected_json).at_path('planning_element_type')
    end

  end
end
