#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

  describe "copy_from_settings uses correct project to copy from" do
    before do
      get 'copy_project', :id => project.id, :coming_from => :settings
    end

    let(:permission) { :copy_projects }
    let(:project) { FactoryGirl.create(:project, :is_public => false) }

    it { assigns(:project).should == project }
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
