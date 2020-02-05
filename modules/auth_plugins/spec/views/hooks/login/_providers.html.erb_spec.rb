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

describe 'rendering the login buttons for all providers' do
  let(:providers) do
    [
      { name: 'mock_auth' },
      { name: 'test_auth', display_name: 'Test' },
      { name: 'foob_auth', icon: 'foobar.png' }
    ]
  end


  before do
    allow(OpenProject::Plugins::AuthPlugin).to receive(:providers).and_return(providers)

    render partial: 'hooks/login/providers', handlers: [:erb], formats: [:html]
  end

  it 'should show the mock_auth button with the name as its label' do
    expect(rendered).to match /#{providers[0][:name]}/
  end

  it 'should show the test_auth button with the given display_name as its label' do
    expect(rendered).to match /#{providers[1][:display_name]}/
  end

  context 'with relative url root', with_config: { rails_relative_url_root: '/foobar' } do
    it 'renders correctly' do
      expect(rendered).to include '/foobar/auth/mock_auth'
    end
  end
end
