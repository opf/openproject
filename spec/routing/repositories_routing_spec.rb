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

describe RepositoriesController do
  describe "show" do
    it{ get("/projects/testproject/repository").should route_to( :controller => 'repositories',
                                                                 :action => 'show',
                                                                 :project_id => 'testproject') }

    it{ get("/projects/testproject/repository/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                :action => 'show',
                                                                                :project_id => 'testproject',
                                                                                :path => 'path/to/file.c') }

    it{ get("/projects/testproject/repository/revisions/5").should route_to( :controller => 'repositories',
                                                                             :action => 'show',
                                                                             :rev => '5',
                                                                             :project_id => 'testproject') }
  end

  describe "edit" do
    it {  get("/projects/testproject/repository/edit").should route_to( :controller => 'repositories',
                                                                        :action => 'edit',
                                                                        :project_id => 'testproject') }

    it { post("/projects/testproject/repository/edit").should route_to( :controller => 'repositories',
                                                                        :action => 'edit',
                                                                        :project_id => 'testproject') }
  end

  describe "revisions" do
    it { get("/projects/testproject/repository/revisions").should      route_to( :controller => 'repositories',
                                                                                 :action => 'revisions',
                                                                                 :project_id => 'testproject') }

    it { get("/projects/testproject/repository/revisions.atom").should route_to( :controller => 'repositories',
                                                                                 :action => 'revisions',
                                                                                 :project_id => 'testproject',
                                                                                 :format => 'atom') }
  end

  describe "revision" do
    it { get("/projects/testproject/repository/revision/2457").should route_to( :controller => 'repositories',
                                                                                :action => 'revision',
                                                                                :project_id => 'testproject',
                                                                                :rev => '2457') }

    it { get("/projects/testproject/repository/revision").should route_to( :controller => 'repositories',
                                                                           :action => 'revision',
                                                                           :project_id => 'testproject') }
  end

  describe "diff" do
    it { get("/projects/testproject/repository/revisions/2457/diff").should route_to( :controller => 'repositories',
                                                                                      :action => 'diff',
                                                                                      :project_id => 'testproject',
                                                                                      :rev => '2457') }

    it { get("/projects/testproject/repository/revisions/2457/diff.diff").should route_to( :controller => 'repositories',
                                                                                           :action => 'diff',
                                                                                           :project_id => 'testproject',
                                                                                           :rev => '2457',
                                                                                           :format => 'diff') }

    it { get("/projects/testproject/repository/diff").should route_to( :controller => 'repositories',
                                                                       :action => 'diff',
                                                                       :project_id => 'testproject') }

    it { get("/projects/testproject/repository/diff/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                      :action => 'diff',
                                                                                      :project_id => 'testproject',
                                                                                      :path => "path/to/file.c") }

    it { get("/projects/testproject/repository/revisions/2/diff/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                                  :action => 'diff',
                                                                                                  :project_id => 'testproject',
                                                                                                  :path => "path/to/file.c",
                                                                                                  :rev => '2')}
  end

  describe "browse" do
    it { get("/projects/testproject/repository/browse/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                        :action => 'browse',
                                                                                        :project_id => 'testproject',
                                                                                        :path => "path/to/file.c") }
  end

  describe "entry" do
    it { get("/projects/testproject/repository/entry/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                       :action => 'entry',
                                                                                       :project_id => 'testproject',
                                                                                       :path => "path/to/file.c") }

    it { get("/projects/testproject/repository/revisions/2/entry/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                                   :action => 'entry',
                                                                                                   :project_id => 'testproject',
                                                                                                   :path => "path/to/file.c",
                                                                                                   :rev => '2') }

    it { get("/projects/testproject/repository/raw/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                     :action => 'entry',
                                                                                     :project_id => 'testproject',
                                                                                     :path => "path/to/file.c",
                                                                                     :format => 'raw') }

    it { get("/projects/testproject/repository/revisions/master/raw/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                                      :action => 'entry',
                                                                                                      :project_id => 'testproject',
                                                                                                      :path => "path/to/file.c",
                                                                                                      :rev => 'master',
                                                                                                      :format => 'raw') }

  end

  describe "annotate" do
    it { get("/projects/testproject/repository/annotate/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                          :action => 'annotate',
                                                                                          :project_id => 'testproject',
                                                                                          :path => "path/to/file.c") }
    it { get("/projects/testproject/repository/revisions/5/annotate/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                                      :action => 'annotate',
                                                                                                      :project_id => 'testproject',
                                                                                                      :path => "path/to/file.c",
                                                                                                      :rev => '5') }
  end

  describe "changes" do
    it { get("/projects/testproject/repository/changes/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                         :action => 'changes',
                                                                                         :project_id => 'testproject',
                                                                                         :path => "path/to/file.c") }

    it { get("/projects/testproject/repository/revisions/5/changes/path/to/file.c").should route_to( :controller => 'repositories',
                                                                                                     :action => 'changes',
                                                                                                     :project_id => 'testproject',
                                                                                                     :path => "path/to/file.c",
                                                                                                     :rev => '5') }
  end

  describe "stats" do
    it { get("/projects/testproject/repository/statistics").should route_to( :controller => 'repositories',
                                                                             :action => 'stats',
                                                                             :project_id => 'testproject') }
  end

  describe "committers" do
    it { get("/projects/testproject/repository/committers").should route_to( :controller => 'repositories',
                                                                             :action => 'committers',
                                                                             :project_id => 'testproject') }

    it { post("/projects/testproject/repository/committers").should route_to( :controller => 'repositories',
                                                                              :action => 'committers',
                                                                              :project_id => 'testproject') }
  end

  describe "graph" do
    it { get("/projects/testproject/repository/graph").should route_to( :controller => 'repositories',
                                                                        :action => 'graph',
                                                                        :project_id => 'testproject') }
  end

  describe "destroy" do
    it { delete("/projects/testproject/repository").should route_to( :controller => 'repositories',
                                                                     :action => 'destroy',
                                                                     :project_id => 'testproject') }
  end
end
