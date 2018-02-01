#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require_relative '../legacy_spec_helper'

describe 'Application', with_settings: { login_required?: false } do
  include Redmine::I18n

  def document_root_element
    html_document.root
  end

  fixtures :all

  it 'set localization' do
    allow(Setting).to receive(:available_languages).and_return [:de, :en]
    allow(Setting).to receive(:default_language).and_return 'en'

    # a french user
    get '/projects', params: {}, headers: { 'HTTP_ACCEPT_LANGUAGE' => 'de,de-de;q=0.8,en-us;q=0.5,en;q=0.3' }
    assert_response :success
    assert_select 'h2', content: 'Projekte'
    assert_equal :de, current_language

    # not a supported language: default language should be used
    get '/projects', params: {}, headers: { 'HTTP_ACCEPT_LANGUAGE' => 'zz' }
    assert_response :success
    assert_select 'h2', content: 'Projects'
  end

  it 'token based access should not start session' do
    # work_packages of a private project
    get '/work_packages/4.atom'
    assert_response 302

    rss_key = User.find(2).rss_key
    get "/work_packages/4.atom?key=#{rss_key}"
    assert_response 200
    assert_nil session[:user_id]
  end
end
