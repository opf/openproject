#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

shared_examples_for 'user contract' do
  let(:user_firstname) { 'Bob' }
  let(:user_lastname) { 'Bobbit' }
  let(:user_login) { 'bob' }
  let(:user_mail) { 'bobbit@bob.com' }
  let(:user_password) { 'adminADMIN!' }
  let(:user_password_confirmation) { 'adminADMIN!' }

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  context 'when admin' do
    let(:current_user) { build_stubbed :admin }

    it_behaves_like 'contract is valid'
  end

  context 'when global user' do
    let(:current_user) { create :user, global_permission: :manage_user }

    describe 'cannot set the password' do
      before do
        user.password = user.password_confirmation = 'password!password!'
      end

      it_behaves_like 'contract is invalid', password: :error_readonly
    end

    describe 'can set the auth_source' do
      let!(:auth_source) { create :auth_source }

      before do
        user.password = user.password_confirmation = nil
        user.auth_source = auth_source
      end

      it_behaves_like 'contract is valid'
    end

    describe 'cannot set the identity url' do
      before do
        user.identity_url = 'saml:123412foo'
      end

      it_behaves_like 'contract is invalid', identity_url: :error_readonly
    end
  end

  context 'when unauthorized user' do
    let(:current_user) { build_stubbed(:user) }

    it_behaves_like 'contract user is unauthorized'
  end
end
