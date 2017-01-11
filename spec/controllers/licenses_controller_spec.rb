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

describe LicensesController, type: :controller do
  let(:a_license) { License.new }
  let(:license_object) {
    license = OpenProject::License.new
    license.licensee =  'Foobar'
    license.mail = 'foo@example.org'
    license.starts_at = Date.today
    license.expires_at = nil

    license
  }

  before do
    login_as user
    allow(a_license).to receive(:license_object).and_return(license_object)
  end

  context 'with admin' do
    let(:user) { FactoryGirl.build(:admin) }

    describe '#show' do
      render_views

      context 'when license exists' do
        before do
          allow(License).to receive(:current).and_return(a_license)
          get :show
        end

        it 'renders the overview' do
          expect(response).to be_success
          expect(response).to render_template 'show'
          expect(response).to render_template partial: 'licenses/_current'
          expect(response).to render_template partial: 'licenses/_form'
        end
      end

      context 'when no license exists' do
        before do
          allow(License).to receive(:current).and_return(nil)
          get :show
        end

        it 'still renders #show with form' do
          expect(response).not_to render_template partial: 'licenses/_current'
          expect(response.body).to have_selector '.upsale-notification'
        end
      end
    end

    describe '#create' do
      let(:params) do
        {
          license: { encoded_license: 'foo' }
        }
      end

      before do
        allow(License).to receive(:new).and_return(a_license)
        expect(a_license).to receive(:encoded_license=).with('foo')
        expect(a_license).to receive(:save).and_return(valid)

        post :create, params: params
      end

      context 'valid license input' do
        let(:valid) { true }

        it 'redirects to index' do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
          expect(response).to redirect_to action: :show
        end
      end

      context 'invalid license input' do
        let(:valid) { false }

        it 'renders with error' do
          expect(response).not_to be_redirect
          expect(response).to render_template 'licenses/show'
        end
      end
    end

    describe '#destroy' do
      context 'when the license exists' do
        before do
          expect(License).to receive(:current).and_return(a_license)
          expect(a_license).to receive(:destroy)

          delete :destroy
        end

        it 'redirects to show' do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_delete)
          expect(response).to redirect_to action: :show
        end
      end

      context 'when no license exists' do
        before do
          expect(License).to receive(:current).and_return(nil)
          delete :destroy
        end

        it 'renders 404' do
          expect(response.status).to eq(404)
        end
      end
    end
  end

  context 'regular user' do
    let(:user) { FactoryGirl.build(:user) }

    before do
      get :show
    end

    it 'is forbidden' do
      expect(response.status).to eq 403
    end
  end
end
