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

describe '/api/v2/users/index.api.rabl', type: :view do

  before do
    params[:format] = 'json'
  end

  subject { response.body }

  describe 'with no project available' do
    it 'renders an empty projects document' do
      assign(:projects, [])

      render

      is_expected.to have_json_size(0).at_path('users')
    end
  end

  describe 'with some projects available' do
    let(:users) {
      [
        FactoryGirl.build(:user, firstname: 'Peter', lastname: 'Test'),
        FactoryGirl.build(:user, firstname: 'Mary', lastname: 'Test'),
      ]
    }

    before do
      # stub out helpers that are defined on the controller
      assign(:users, users)
      render
    end

    subject { response.body }

    it 'renders a projects document with the size of 3 of type array' do
      is_expected.to have_json_size(2).at_path('users')
    end

    it 'renders both users' do

      is_expected.to be_json_eql({ firstname: 'Peter', lastname: 'Test', name: 'Peter Test' }.to_json).at_path('users/0')
      is_expected.to be_json_eql({ firstname: 'Mary', lastname: 'Test', name: 'Mary Test' }.to_json).at_path('users/1')

    end

  end
end
