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

require 'spec_helper'

describe Api::V2::Pagination::PrincipalsController do
  it "should connect GET /api/v2/pagination/principals to principals#edit" do
    get("/api/v2/pagination/principals").should route_to(:controller => 'api/v2/pagination/principals',
                                                         :action => 'index')
  end
end

describe Api::V2::Pagination::UsersController do
  it "should connect GET /api/v2/pagination/users to users#edit" do
    get("/api/v2/pagination/users").should route_to(:controller => 'api/v2/pagination/users',
                                                    :action => 'index')
  end
end

describe Api::V2::Pagination::StatusesController do
  it "should connect GET /api/v2/pagination/users to statuses#edit" do
    get("/api/v2/pagination/statuses").should route_to(:controller => 'api/v2/pagination/statuses',
                                                       :action => 'index')
  end
end

describe Api::V2::Pagination::TypesController do
  it "should connect GET /api/v2/pagination/types to types#edit" do
    get("/api/v2/pagination/types").should route_to(:controller => 'api/v2/pagination/types',
                                                    :action => 'index')
  end
end

describe Api::V2::Pagination::ProjectTypesController do
  it "should connect GET /api/v2/pagination/project_types to project_types#edit" do
    get("/api/v2/pagination/project_types").should route_to(:controller => 'api/v2/pagination/project_types',
                                                            :action => 'index')
  end
end

describe Api::V2::Pagination::ReportedProjectStatusesController do
  it "should connect GET /api/v2/pagination/reported_project_statuses to reported_project_statuses#edit" do
    get("/api/v2/pagination/reported_project_statuses").should route_to(:controller => 'api/v2/pagination/reported_project_statuses',
                                                                        :action => 'index')
  end
end

describe Api::V2::Pagination::ProjectsController do
  it "should connect GET /api/v2/pagination/projects to projects#edit" do
    get("/api/v2/pagination/projects").should route_to(:controller => 'api/v2/pagination/projects',
                                                       :action => 'index')
  end
end
