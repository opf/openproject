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

require File.expand_path('../../../spec_helper', __FILE__)

describe "API v2" do

  let(:admin) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create(:project) }

  before do
    @api_key = admin.api_key

    Setting.stub(:login_required?).and_return true
    Setting.stub(:rest_api_enabled?).and_return true
  end

  after do
    User.current = nil # api key auth sets the current user, reset it to make test idempotent
  end

  describe "key authentication" do
    describe "for planning element types" do
      it "should reject an invalid key" do
        get "/api/v2/projects/#{project.id}/planning_element_types.json?key=invalidkey"

        response.status.should == 401
      end

      it "should accept a valid key" do
        get "/api/v2/projects/#{project.id}/planning_element_types.json?key=#{@api_key}"

        response.status.should == 200
      end
    end

    describe "for project associations" do
      it "should reject an invalid key" do
        get "/api/v2/projects/#{project.id}/project_associations.xml"

        response.status.should == 401
      end

      it "should accept a valid key" do
        get "/api/v2/projects/#{project.id}/project_associations.xml?key=#{@api_key}"

        response.status.should == 200
      end
    end

    describe "for project associations' available projects" do
      it "should reject an invalid key" do
        get "/api/v2/projects/#{project.id}/project_associations/available_projects.xml"

        response.status.should == 401
      end

      it "should accept a valid key" do
        get "/api/v2/projects/#{project.id}/project_associations/available_projects.xml?key=#{@api_key}"

        response.status.should == 200
      end
    end

    describe "for reportings" do
      it "should reject an invalid key" do
        get "/api/v2/projects/#{project.id}/reportings.xml"

        response.status.should == 401
      end

      it "should accept a valid key" do
        get "/api/v2/projects/#{project.id}/reportings.xml?key=#{@api_key}"

        response.status.should == 200
      end
    end

    describe "for reportings' available projects" do
      it "should reject an invalid key" do
        get "/api/v2/projects/#{project.id}/reportings/available_projects.xml"

        response.status.should == 401
      end

      it "should accept a valid key" do
        get "/api/v2/projects/#{project.id}/reportings/available_projects.xml?key=#{@api_key}"

        response.status.should == 200
      end
    end
  end
end
