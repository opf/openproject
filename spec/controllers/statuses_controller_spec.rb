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

describe StatusesController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }
  let(:status) { FactoryBot.create(:status) }

  before do allow(User).to receive(:current).and_return user end

  shared_examples_for :response do
    subject { response }

    it { is_expected.to be_successful }

    it { is_expected.to render_template(template) }
  end

  shared_examples_for :redirect do
    subject { response }

    it { is_expected.to be_redirect }

    it { is_expected.to redirect_to(action: :index) }
  end

  shared_examples_for :statuses do
    subject { Status.find_by(name: name) }

    it { is_expected.not_to be_nil }
  end

  describe '#index' do
    let(:template) { 'index' }

    before do get :index end

    it_behaves_like :response
  end

  describe '#new' do
    let(:template) { 'new' }

    before do get :new end

    it_behaves_like :response
  end

  describe '#create' do
    let(:name) { 'New Status' }

    before do
      post :create,
           params: { status: { name: name } }
    end

    it_behaves_like :statuses

    it_behaves_like :redirect
  end

  describe '#edit' do
    let(:template) { 'edit' }

    context 'default' do
      let!(:status_default) {
        FactoryBot.create(:status,
                           is_default: true)
      }

      before do
        get :edit,
            params: { id: status_default.id }
      end

      it_behaves_like :response

      describe '#view' do
        render_views

        it do
        assert_select 'p',
                        {content: Status.human_attribute_name(:is_default)}, false
        end
      end
    end

    context 'no_default' do
      before do
        status

        get :edit, params: { id: status.id }
      end

      it_behaves_like :response

      describe '#view' do
        render_views

        it do
        assert_select 'div',
                     content: Status.human_attribute_name(:is_default)
        end
      end
    end
  end

  describe '#update' do
    let(:name) { 'Renamed Status' }

    before do
      status

      patch :update,
            params: {
              id: status.id,
              status: { name: name }
            }
    end

    it_behaves_like :statuses

    it_behaves_like :redirect
  end

  describe '#destroy' do
    let(:name) { status.name }

    shared_examples_for :destroyed do
      subject { Status.find_by(name: name) }

      it { is_expected.to be_nil }
    end

    context 'unused' do
      before do
        status

        delete :destroy, params: { id: status.id }
      end

      it_behaves_like :destroyed

      it_behaves_like :redirect
    end

    context 'used' do
      let(:work_package) {
        FactoryBot.create(:work_package,
                           status: status)
      }

      before do
        work_package

        delete :destroy, params: { id: status.id }
      end

      it_behaves_like :statuses

      it_behaves_like :redirect
    end

    context 'default' do
      let!(:status_default) {
        FactoryBot.create(:status,
                           is_default: true)
      }

      before do
        delete :destroy, params: { id: status_default.id }
      end

      it_behaves_like :statuses

      it_behaves_like :redirect

      it 'shows the right flash message' do
        expect(flash[:error]).to eq(I18n.t('error_unable_delete_default_status'))
      end
    end
  end

  describe '#update_work_package_done_ratio' do
    shared_examples_for :flash do
      it { is_expected.to set_flash.to(message) }
    end

    context "with 'work_package_done_ratio' using 'field'" do
      let(:message) { /not updated/ }

      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return 'field'

        post :update_work_package_done_ratio
      end

      it_behaves_like :flash

      it_behaves_like :redirect
    end

    context "with 'work_package_done_ratio' using 'status'" do
      let(:message) { /Work package done ratios updated/ }

      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return 'status'

        post :update_work_package_done_ratio
      end

      it_behaves_like :flash

      it_behaves_like :redirect
    end
  end
end
