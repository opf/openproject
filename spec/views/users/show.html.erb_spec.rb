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

require 'spec_helper'

describe 'users/show', type: :view do
  let(:project)    { FactoryGirl.create :valid_project }
  let(:user)       { FactoryGirl.create :admin, member_in_project: project }
  let(:custom_field) { FactoryGirl.create :text_user_custom_field }
  let(:visibility_custom_value) {
    FactoryGirl.create(:principal_custom_value,
                       customized: user,
                       custom_field: custom_field,
                       value: 'TextUserCustomFieldValue')
  }

  before do
    visibility_custom_value
    user.reload
    assign(:user, user)
    assign(:memberships, user.memberships.all)
    assign(:events_by_day, [])
  end

  it 'renders the visible custom values' do
    render

    expect(response).to have_selector('li', text: 'TextUserCustomField')
  end
end
