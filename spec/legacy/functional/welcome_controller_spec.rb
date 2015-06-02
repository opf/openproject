#-- encoding: UTF-8
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
require 'legacy_spec_helper'
require 'welcome_controller'

describe WelcomeController, type: :controller do
  render_views

  fixtures :all

  before do
    Setting.available_languages = [:en, :de]
    User.current = nil
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:news)
    assert_not_nil assigns(:projects)
    assert !assigns(:projects).include?(Project.find(:first, conditions: { is_public: false }))
  end

  it 'should browser language' do
    Setting.default_language = 'en'
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'de,de-de;q=0.8,en-us;q=0.5,en;q=0.3'
    get :index
    assert_equal :de, @controller.current_language
  end

  it 'should browser language alternate' do
    Setting.default_language = 'en'
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'de'
    get :index
    assert_equal :"de", @controller.current_language
  end

  it 'should browser language alternate not valid' do
    Setting.default_language = 'en'
    request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-CA'
    get :index
    assert_equal :de, @controller.current_language
  end

  it 'should robots' do
    get :robots, format: :txt
    assert_response :success
    assert_equal 'text/plain', response.content_type
    assert response.body.match(%r{^Disallow: /projects/ecookbook/issues\r?$})
  end

  it 'should warn on leaving unsaved turn on' do
    user = User.find(2)
    user.pref.warn_on_leaving_unsaved = '1'
    user.pref.save!
    session[:user_id] = 2

    get :index
    assert_tag 'script',
               attributes: { type: 'text/javascript' },
               content: /warnLeavingUnsaved/
  end

  it 'should warn on leaving unsaved turn off' do
    user = User.find(2)
    user.pref.warn_on_leaving_unsaved = '0'
    user.pref.save!
    session[:user_id] = 2

    get :index
    assert_no_tag 'script',
                  attributes: { type: 'text/javascript' },
                  content: /warnLeavingUnsaved/
  end
end
