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

describe ReportingsController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
    FactoryGirl.create(:non_member)
  end

  describe 'index.html' do
    let(:project) { FactoryGirl.create(:project) }
    def fetch
      get 'index', params: { project_id: project.identifier }
    end
    let(:permission) { :view_reportings }
    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'show.html' do
    let(:project)   { FactoryGirl.create(:project) }
    let(:reporting) { FactoryGirl.create(:reporting, project_id: project.id) }
    def fetch
      get 'show', params: { project_id: project.identifier, id: reporting.id }
    end
    let(:permission) { :view_reportings }
    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'new.html' do
    let(:project)   { FactoryGirl.create(:project) }
    def fetch
      FactoryGirl.create(:public_project) # reporting candidate

      get 'new', params: { project_id: project.identifier }
    end
    let(:permission) { :edit_reportings }
    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'create.html' do
    let(:project)   { FactoryGirl.create(:project) }
    def fetch
      post 'create',
           params: {
             project_id: project.identifier,
             reporting: FactoryGirl.build(:reporting, project_id: project.id).attributes
           }
    end
    let(:permission) { :edit_reportings }
    def expect_redirect_to
      project_reportings_path(project)
    end
    it_should_behave_like 'a controller action which needs project permissions'

    it 'should not create a reporting w/o a reporting project' do
      post :create,
           params: {
             project_id: project.identifier,
             reporting: FactoryGirl.build(
               :reporting,
               project_id: project.id,
               reporting_to_project_id: nil
             ).attributes
           }

      expect(response).to render_template(:new)
    end
  end

  describe 'edit.html' do
    let(:project)   { FactoryGirl.create(:project) }
    let(:reporting) { FactoryGirl.create(:reporting, project_id: project.id) }

    def fetch
      get 'edit',
          params: { project_id: project.identifier, id: reporting.id }
    end
    let(:permission) { :edit_reportings }
    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'update.html' do
    let(:project)   { FactoryGirl.create(:project) }
    let(:reporting) { FactoryGirl.create(:reporting, project_id: project.id) }

    def fetch
      post 'update',
           params: { project_id: project.identifier, id: reporting.id, reporting: {} }
    end
    let(:permission) { :edit_reportings }
    def expect_redirect_to
      project_reportings_path(project)
    end
    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'confirm_destroy.html' do
    let(:project)   { FactoryGirl.create(:project) }
    let(:reporting) { FactoryGirl.create(:reporting, project_id: project.id) }

    def fetch
      get 'confirm_destroy',
          params: { project_id: project.identifier, id: reporting.id }
    end
    let(:permission) { :delete_reportings }
    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'update.html' do
    let(:project)   { FactoryGirl.create(:project) }
    let(:reporting) { FactoryGirl.create(:reporting, project_id: project.id) }

    def fetch
      post 'destroy',
           params: { project_id: project.identifier, id: reporting.id }
    end
    let(:permission) { :delete_reportings }
    def expect_redirect_to
      project_reportings_path(project)
    end
    it_should_behave_like 'a controller action which needs project permissions'
  end
end
