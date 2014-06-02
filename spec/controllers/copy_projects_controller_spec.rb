#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require File.expand_path('../../spec_helper', __FILE__)

describe CopyProjectsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  shared_context 'start copy project' do
    before { get 'copy_project', id: project.id, coming_from: :settings }
  end

  describe 'copy_from_settings' do
    let(:permission) { :copy_projects }
    let(:project) { FactoryGirl.create(:project, is_public: false) }


    describe 'uses correct project to copy from' do
      include_context 'start copy project'

      it { expect(assigns(:project)).to eq(project) }
    end

    describe 'work package limit' do
      context 'is 0' do
        include_context 'start copy project'

        it { expect(assigns(:copy_work_packages)).to be_true }
      end

      context 'is 1' do
        before do
          FactoryGirl.create(:work_package, project: project)
          FactoryGirl.create(:work_package, project: project)

          Setting.stub(:work_package_count_on_copy).and_return('1')
        end

        include_context 'start copy project'

        it { expect(assigns(:copy_work_packages)).to be_false }

        it { expect(flash.now[:warning]).to include(I18n.t(:label_work_package_copy_count_exceeded)) }
      end
    end
  end

  describe 'copy_from_settings permissions' do
    def fetch
      get 'copy_project', :id => project.id, :coming_from => :settings
    end

    let(:permission) { :copy_projects }
    let(:project) { FactoryGirl.create(:project, :is_public => false) }

    it_should_behave_like "a controller action which needs project permissions"
  end

  describe 'copy creates a new project' do
    before do
      post 'copy',
           :id => project.id,
           :project => project.attributes.reject { |k,v| v.nil? }.merge({ :identifier => "copy", :name => "copy" })
    end

    def expect_redirect_to
      true
    end

    let(:permission) { :copy_projects }
    let(:project) { FactoryGirl.create(:project, :is_public => false) }

    it { assigns(:project).should_not == project }
  end

  describe 'copy permissions' do
    def fetch
      post 'copy',
           :id => project.id,
           :project => project.attributes.reject { |k,v| v.nil? }.merge({ :identifier => "copy", :name => "copy" })
    end

    def expect_redirect_to
      true
    end

    let(:permission) { [:copy_projects, :add_project] }
    let(:project) { FactoryGirl.create(:project, :is_public => false) }

    it_should_behave_like "a controller action which needs project permissions"
  end
end
