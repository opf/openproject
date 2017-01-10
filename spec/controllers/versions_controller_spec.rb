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

describe VersionsController, type: :controller do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:public_project) }
  let(:version1) { FactoryGirl.create(:version, project: project, effective_date: nil) }
  let(:version2) { FactoryGirl.create(:version, project: project) }
  let(:version3) { FactoryGirl.create(:version, project: project, effective_date: (Date.today - 14.days)) }

  describe '#index' do
    render_views

    before do
      version1
      version2
      version3
    end

    context 'without additional params' do
      before do
        login_as(user)
        get :index, params: { project_id: project.id }
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template('index') }

      subject { assigns(:versions) }
      it 'shows Version with no date set' do
        expect(subject.include?(version1)).to be_truthy
      end
      it 'shows Version with date set' do
        expect(subject.include?(version2)).to be_truthy
      end
      it 'not shows Completed version' do
        expect(subject.include?(version3)).to be_falsey
      end
    end

    context 'with showing completed versions' do
      before do
        login_as(user)
        get :index, params: { project_id: project, completed: '1' }
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template('index') }

      subject { assigns(:versions) }
      it 'shows Version with no date set' do
        expect(subject.include?(version1)).to be_truthy
      end
      it 'shows Version with date set' do
        expect(subject.include?(version2)).to be_truthy
      end
      it 'not shows Completed version' do
        expect(subject.include?(version3)).to be_truthy
      end
    end

    context 'with showing subprojects versions' do
      let(:sub_project) { FactoryGirl.create(:public_project, parent_id: project.id) }
      let(:version4) { FactoryGirl.create(:version, project: sub_project) }

      before do
        login_as(user)
        version4
        get :index, params: { project_id: project, with_subprojects: '1' }
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template('index') }

      subject { assigns(:versions) }
      it 'shows Version with no date set' do
        expect(subject.include?(version1)).to be_truthy
      end
      it 'shows Version with date set' do
        expect(subject.include?(version2)).to be_truthy
      end
      it 'shows Version from sub project' do
        expect(subject.include?(version4)).to be_truthy
      end
    end
  end

  describe '#show' do
    render_views

    before do
      login_as(user)
      version2
      get :show, params: { id: version2.id }
    end

    it { expect(response).to be_success }
    it { expect(response).to render_template('show') }
    it {assert_select 'h2', content: version2.name }

    subject { assigns(:version) }
    it { is_expected.to eq(version2) }
  end

  describe '#new' do
    # This spec is here because at one point the `new` action was requiring
    # the `version` key in params, so visiting it without one failed.
    it 'renders correctly' do
      login_as(user)
      get :new, params: { project_id: project.id }
      expect(response.status).to eq(200)
    end
  end

  describe '#create' do
    context 'with vaild attributes' do
      before do
        login_as(user)
        post :create, params: { project_id: project.id, version: { name: 'test_add_version' } }
      end

      it { expect(response).to redirect_to(settings_project_path(project, tab: 'versions')) }
      it 'generates the new version' do
        version = Version.find_by(name: 'test_add_version')
        expect(version).not_to be_nil
        expect(version.project).to eq(project)
      end
    end
  end

  describe '#edit' do
    render_views

    before do
      login_as(user)
      version2
      get :edit, params: { id: version2.id }
    end

    context 'when resource is found' do
      it { expect(response).to be_success }
      it { expect(response).to render_template('edit') }
    end
  end

  describe '#close_completed' do
    before do
      login_as(user)
      version1.update_attribute :status, 'open'
      version2.update_attribute :status, 'open'
      version3.update_attribute :status, 'open'
      put :close_completed, params: { project_id: project.id }
    end

    it { expect(response).to redirect_to(settings_project_path(project, tab: 'versions')) }
    it { expect(Version.find_by(status: 'closed')).to eq(version3) }
  end

  describe '#update' do
    context 'with valid params' do
      let(:params) {
        {
          id: version1.id,
          version: {
            name: 'New version name',
            effective_date: Date.today.strftime('%Y-%m-%d')
          }
        }
      }
      before do
        login_as(user)
        patch :update, params: params
      end

      it { expect(response).to redirect_to(settings_project_path(project, tab: 'versions')) }
      it { expect(Version.find_by(name: 'New version name')).to eq(version1) }
      it { expect(version1.reload.effective_date).to eq(Date.today) }
    end

    context "with valid params
             with a redirect url" do
      before do
        login_as(user)
        patch :update,
              params: {
                id: version1.id,
                version: { name: 'New version name',
                           effective_date: Date.today.strftime('%Y-%m-%d') },
                back_url: home_path
              }
      end

      it { expect(response).to redirect_to(home_path) }
    end

    context 'with invalid params' do
      before do
        login_as(user)
        patch :update,
              params: {
                id: version1.id,
                version: { name: '',
                           effective_date: Date.today.strftime('%Y-%m-%d') }
              }
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template('edit') }
    end
  end

  describe '#destroy' do
    before do
      login_as(user)
      @deleted = version3.id
      delete :destroy, params: { id: @deleted }
    end

    it 'redirects to projects versions and the version is deleted' do
      expect(response).to redirect_to(settings_project_path(project, tab: 'versions'))
      expect { Version.find(@deleted) }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe '#status_by' do
    before do
      login_as(user)
    end

    context 'status by version' do
      before do
        get :status_by,
            xhr: true,
            params: { id: version2.id }, format: :js
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template('versions/_work_package_counts') }
    end

    context 'status by version with status_by' do
      before do
        get :status_by,
            xhr: true,
            params: { id: version2.id, status_by: 'status' },
            format: :js
      end

      it { expect(response).to be_success }
      it { expect(response).to render_template('versions/_work_package_counts') }
    end
  end
end
