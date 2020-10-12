#-- encoding: UTF-8

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

describe 'Localization', type: :feature, with_settings: { login_required?: false,
                                                          available_languages: %i[de en],
                                                          default_language: 'en' } do

  it 'set localization' do
    Capybara.current_session.driver.header('Accept-Language', 'de,de-de;q=0.8,en-us;q=0.5,en;q=0.3')

    # a french user
    visit projects_path

    expect(page)
      .to have_content('Projekte')

    # not a supported language: default language should be used
    Capybara.current_session.driver.header('Accept-Language', 'zz')
    visit projects_path

    expect(page)
      .to have_content('Projects')
  end
end
