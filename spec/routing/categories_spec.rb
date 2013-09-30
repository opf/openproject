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

describe CategoriesController do

  it "should connect GET /projects/test/categories/new to categories#new" do
    get("/projects/test/categories/new").should route_to( controller: 'categories',
                                                          action: 'new',
                                                          project_id: 'test' )
  end

  it "should connect POST /projects/test/categories to categories#create" do
    post("/projects/test/categories").should route_to( controller: 'categories',
                                                       action: 'create',
                                                       project_id: 'test' )
  end

  it "should connect GET /categories/5/edit to categories#edit" do
    get("/categories/5/edit").should route_to( controller: 'categories',
                                                            action: 'edit',
                                                            id: '5' )
  end

  it "should connect PUT /categories/5 to categories#update" do
    put("/categories/5").should route_to( controller: 'categories',
                                          action: 'update',
                                          id: '5' )
  end

  it "should connect DELETE /categories/5 to categories#delete" do
    delete("/categories/5").should route_to( controller: 'categories',
                                             action: 'destroy',
                                             id: '5' )
  end
end
