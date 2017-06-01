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

describe ProjectAssociationsController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'index.html' do
    let(:project) { FactoryGirl.create(:project, is_public: false) }
    def fetch
      get 'index', params: { project_id: project.identifier }
    end
    let(:permission) { :view_project_associations }

    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'new.html' do
    let(:project) { FactoryGirl.create(:project, is_public: false) }
    def fetch
      get 'new', params: { project_id: project.identifier }
    end
    let(:permission) { :edit_project_associations }

    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'create.html' do
    let(:project)   { FactoryGirl.create(:project, is_public: false) }
    let(:project_b) { FactoryGirl.create(:project, is_public: true) }
    def fetch
      post 'create',
           params: {
             project_id: project.identifier,
             project_association: { project_b_id: project_b.id }
           }
    end
    let(:permission) { :edit_project_associations }
    def expect_redirect_to
      Regexp.new(project_project_associations_path(project))
    end

    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'edit.html' do
    let(:project)   { FactoryGirl.create(:project, is_public: false) }
    let(:project_b) { FactoryGirl.create(:project, is_public: true) }
    let(:project_association) {
      FactoryGirl.create(:project_association,
                         project_a_id: project.id,
                         project_b_id: project_b.id)
    }
    def fetch
      get 'edit',
          params: {
            project_id: project.identifier,
            id: project_association.id
          }
    end
    let(:permission) { :edit_project_associations }

    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'update.html' do
    let(:project)   { FactoryGirl.create(:project, is_public: false) }
    let(:project_b) { FactoryGirl.create(:project, is_public: true) }
    let(:project_association) {
      FactoryGirl.create(:project_association,
                         project_a_id: project.id,
                         project_b_id: project_b.id)
    }
    def fetch
      post 'update',
           params: {
             project_id: project.identifier,
             id: project_association.id,
             project_association: {}
           }
    end
    let(:permission) { :edit_project_associations }
    def expect_redirect_to
      project_project_associations_path(project)
    end

    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'confirm_destroy.html' do
    let(:project)   { FactoryGirl.create(:project, is_public: false) }
    let(:project_b) { FactoryGirl.create(:project, is_public: true) }
    let(:project_association) {
      FactoryGirl.create(:project_association,
                         project_a_id: project.id,
                         project_b_id: project_b.id)
    }
    def fetch
      get 'confirm_destroy',
          params: {
            project_id: project.identifier,
            id: project_association.id,
            project_association: {}
          }
    end
    let(:permission) { :delete_project_associations }

    it_should_behave_like 'a controller action which needs project permissions'
  end

  describe 'destroy.html' do
    let(:project)   { FactoryGirl.create(:project, is_public: false) }
    let(:project_b) { FactoryGirl.create(:project, is_public: true) }
    let(:project_association) {
      FactoryGirl.create(:project_association,
                         project_a_id: project.id,
                         project_b_id: project_b.id)
    }
    def fetch
      post 'destroy',
           params: {
             project_id: project.identifier,
             id: project_association.id
           }
    end
    let(:permission) { :delete_project_associations }
    def expect_redirect_to
      project_project_associations_path(project)
    end

    it_should_behave_like 'a controller action which needs project permissions'
  end
end
