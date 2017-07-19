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
require 'settings_controller'

describe SettingsController, type: :controller do
  fixtures :all

  before do
    User.current = nil
    session[:user_id] = 1 # admin
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'edit'
  end

  it 'should get edit' do
    get :edit
    assert_response :success
    assert_template 'edit'
  end

  it 'should post edit notifications' do
    post :edit,
         params: {
           settings: {
             mail_from: 'functional@test.foo',
             bcc_recipients:  '0',
             notified_events: %w(work_package_added work_package_updated news_added),
             emails_footer: 'Test footer'
           }
         }
    assert_redirected_to '/settings/edit'
    assert_equal 'functional@test.foo', Setting.mail_from
    assert !Setting.bcc_recipients?
    assert_equal %w(work_package_added work_package_updated news_added), Setting.notified_events
    assert_equal 'Test footer', Setting.emails_footer
  end
end
