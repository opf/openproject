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

describe 'users/show', type: :view do
  let(:project)    { FactoryBot.create :valid_project }
  let(:user)       { FactoryBot.create :admin, member_in_project: project }
  let(:custom_field) { FactoryBot.create :text_user_custom_field }
  let(:visibility_custom_value) do
    FactoryBot.create(:principal_custom_value,
                      customized: user,
                      custom_field: custom_field,
                      value: 'TextUserCustomFieldValue')
  end

  before do
    visibility_custom_value
    user.reload

    assign(:user, user)
    assign(:memberships, user.memberships)
    assign(:events_by_day, [])
  end

  it 'renders the visible custom values' do
    render

    expect(rendered).to have_selector('li', text: 'TextUserCustomField')
  end
end
