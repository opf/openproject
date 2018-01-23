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

require 'spec_helper'

describe CustomActionsController, type: :controller do
  let(:admin) { FactoryGirl.build(:admin) }
  let(:non_admin) { FactoryGirl.build(:user) }

  describe '#index' do
    context 'for admins' do
      before do
        login_as(admin)

        get :index
      end

      it 'returns 200' do
        expect(response.response_code)
          .to eql 200
      end

      it 'renders index template' do
        expect(response)
          .to render_template('index')
      end
    end

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :index
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#new' do
    context 'for admins' do
      before do
        login_as(admin)

        get :new
      end

      it 'returns 200' do
        expect(response.response_code)
          .to eql 200
      end

      it 'renders new template' do
        expect(response)
          .to render_template('new')
      end

      it 'assigns custom_action' do
        expect(assigns(:custom_action))
          .not_to be_nil
      end
    end

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :new
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end

  describe '#create' do
    context 'for admins' do
      before do
        login_as(admin)

        post :create
      end

      it 'redirects to index' do
        expect(response)
          .to redirect_to(custom_actions_path)
      end
    end

    context 'for non admins' do
      before do
        login_as(non_admin)
        get :new
      end

      it 'returns 403' do
        expect(response.response_code)
          .to eql 403
      end
    end
  end
end
