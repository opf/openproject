#-- encoding: UTF-8
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
require File.expand_path('../../test_helper', __FILE__)

class RoutingTest < ActionDispatch::IntegrationTest
  context "activities" do
    should route(:get, "/activity").to( :controller => 'activities',
                                        :action => 'index' )
    should route(:get, "/activity.atom").to( :controller => 'activities',
                                             :action => 'index',
                                             :format => 'atom' )

    should "route /activities to activities#index" do
      assert_recognizes({ :controller => 'activities', :action => 'index' }, "/activities")
    end
    should "route /activites.atom to activities#index" do
      assert_recognizes({ :controller => 'activities', :action => 'index', :format => 'atom' }, "/activities.atom")
    end

    should route(:get, "projects/eCookbook/activity").to( :controller => 'activities',
                                                          :action => 'index',
                                                          :project_id => "eCookbook" )

    should route(:get, "projects/eCookbook/activity.atom").to( :controller => 'activities',
                                                               :action => 'index',
                                                               :project_id => "eCookbook",
                                                               :format => 'atom')

    should "route project/eCookbook/activities to activities#index" do
      assert_recognizes({ :controller => 'activities', :action => 'index', :project_id => "eCookbook" }, "/projects/eCookbook/activities")
    end
    should "route project/eCookbook/activites.atom to activities#index" do
      assert_recognizes({ :controller => 'activities', :action => 'index', :format => 'atom', :project_id => "eCookbook" }, "/projects/eCookbook/activities.atom")
    end
  end

  context "attachments" do
    should route(:get, "/attachments/1").to( :controller => 'attachments',
                                             :action => 'show',
                                             :id => '1')
    should route(:get, "/attachments/1/filename.ext").to( :controller => 'attachments',
                                                          :action => 'show',
                                                          :id => '1',
                                                          :filename => 'filename.ext' )
    should route(:get, "/attachments/1/download").to( :controller => 'attachments',
                                                      :action => 'download',
                                                      :id => '1' )
    should route(:get, "/attachments/1/download/filename.ext").to( :controller => 'attachments',
                                                                   :action => 'download',
                                                                   :id => '1',
                                                                   :filename => 'filename.ext' )
    should "redirect /atttachments/download/1 to /attachments/1/download" do
      get '/attachments/download/1'
      assert_redirected_to '/attachments/1/download'
    end

    should "redirect /atttachments/download/1/filename.ext to /attachments/1/download/filename.ext" do
      get '/attachments/download/1/filename.ext'
      assert_redirected_to '/attachments/1/download/filename.ext'
    end

    should route(:delete, "/attachments/1").to( :controller => 'attachments',
                                                :action => 'destroy',
                                                :id => '1')
  end

  context "boards" do
    should route(:get, "/projects/world_domination/boards").to( :controller => 'boards',
                                                                :action => 'index',
                                                                :project_id => 'world_domination')
    should route(:get, "/projects/world_domination/boards/new").to( :controller => 'boards',
                                                                    :action => 'new',
                                                                    :project_id => 'world_domination')
    should route(:post, "/projects/world_domination/boards").to( :controller => 'boards',
                                                                 :action => 'create',
                                                                 :project_id => 'world_domination')
    should route(:get, "/projects/world_domination/boards/44").to( :controller => 'boards',
                                                                   :action => 'show',
                                                                   :project_id => 'world_domination',
                                                                   :id => '44')
    should route(:get, "/projects/world_domination/boards/44.atom").to( :controller => 'boards',
                                                                        :action => 'show',
                                                                        :project_id => 'world_domination',
                                                                        :id => '44',
                                                                        :format => 'atom')
    should route(:get, "/projects/world_domination/boards/44/edit").to( :controller => 'boards',
                                                                       :action => 'edit',
                                                                       :project_id => 'world_domination',
                                                                       :id => '44')
    should route(:put, "/projects/world_domination/boards/44").to( :controller => 'boards',
                                                                   :action => 'update',
                                                                   :project_id => 'world_domination',
                                                                        :id => '44')
    should route(:delete, "/projects/world_domination/boards/44").to( :controller => 'boards',
                                                                      :action => 'destroy',
                                                                      :project_id => 'world_domination',
                                                                      :id => '44')

  end

  context "issues" do
    # REST actions
    should route(:get, "/api/v1/issues.xml").to( :controller => 'api/v1/issues',
                                                 :action => 'index',
                                                 :format => 'xml')
    should route(:get, "/api/v1/projects/23/issues.xml").to( :controller => 'api/v1/issues',
                                                             :action => 'index',
                                                             :project_id => '23',
                                                             :format => 'xml')
    should route(:get, "/api/v1/issues/64.xml").to( :controller => 'api/v1/issues',
                                                    :action => 'show',
                                                    :id => '64',
                                                    :format => 'xml')
    should route(:get, "/api/v1/projects/23/issues/new.xml").to( :controller => 'api/v1/issues',
                                                                 :action => 'new',
                                                                 :project_id => '23',
                                                                 :format => 'xml' )
    should route(:delete, "/api/v1/issues/1.xml").to( :controller => 'api/v1/issues',
                                                      :action => 'destroy',
                                                      :id => '1',
                                                      :format => 'xml')

    # Extra actions
    should route(:get, "/issues/changes").to( :controller => 'journals',
                                              :action => 'index')
  end


  context "enumerations" do
    context "within admin" do
      should route(:get, "admin/enumerations").to( :controller => 'enumerations',
                                                   :action => 'index' )

      should route(:get, "admin/enumerations/new").to( :controller => 'enumerations',
                                                      :action => 'new' )

      should route(:post, "admin/enumerations").to( :controller => 'enumerations',
                                                    :action => 'create' )

      should route(:get, "admin/enumerations/1/edit").to( :controller => 'enumerations',
                                                          :action => 'edit',
                                                          :id => '1' )

      should route(:put, "admin/enumerations/1").to( :controller => 'enumerations',
                                                     :action => 'update',
                                                     :id => '1' )

      should route(:delete, "admin/enumerations/1").to( :controller => 'enumerations',
                                                        :action => 'destroy',
                                                        :id => '1' )
    end
  end

  context "roles" do
    context "witin admin" do
      should route(:get, "admin/roles").to( :controller => 'roles',
                                            :action => 'index' )

      should route(:get, "admin/roles/new").to( :controller => 'roles',
                                                :action => 'new' )

      should route(:post, "admin/roles").to( :controller => 'roles',
                                             :action => 'create' )

      should route(:get, "admin/roles/1/edit").to( :controller => 'roles',
                                                   :action => 'edit',
                                                   :id => '1' )

      should route(:put, "admin/roles/1").to( :controller => 'roles',
                                              :action => 'update',
                                              :id => '1' )

      should route(:delete, "admin/roles/1").to( :controller => 'roles',
                                                 :action => 'destroy',
                                                 :id => '1' )

      should route(:get, "admin/roles/report").to( :controller => 'roles',
                                                   :action => 'report' )

      should route(:put, "admin/roles").to( :controller => 'roles',
                                            :action => 'bulk_update' )
    end
  end


  context "journals" do
    should route(:get, "/journals/100/diff/description").to( :controller => 'journals',
                                                             :action => 'diff',
                                                             :id => '100',
                                                             :field => 'description' )
  end

  context "members" do
    context "project scoped" do
      should route(:post, "/projects/5234/members").to( :controller => 'members',
                                                        :action => 'create',
                                                        :project_id => '5234' )

      should route(:get, "/projects/5234/members/autocomplete").to( :controller => 'members',
                                                                    :action => 'autocomplete',
                                                                    :project_id => '5234' )
    end

    should route(:put, "/members/5234").to( :controller => 'members',
                                            :action => 'update',
                                            :id => '5234' )

    should route(:delete, "/members/5234").to( :controller => 'members',
                                               :action => 'destroy',
                                               :id => '5234' )
  end

  context "messages" do
    context "project scoped" do
      should route(:get, "/boards/lala/topics/new").to( :controller => 'messages',
                                                       :action => 'new',
                                                       :board_id => 'lala' )

      should route(:post, "/boards/lala/topics").to( :controller => 'messages',
                                                     :action => 'create',
                                                     :board_id => 'lala' )

      should route(:post, "/boards/22/topics/preview").to( :controller => 'messages',
                                                           :action => 'preview',
                                                           :board_id => '22' )

    end

    should route(:get, "/topics/2").to( :controller => 'messages',
                                        :action => 'show',
                                        :id => '2' )

    should route(:get, "/topics/22/edit").to( :controller => 'messages',
                                              :action => 'edit',
                                              :id => '22' )

    should route(:put, "/topics/22").to( :controller => 'messages',
                                         :action => 'update',
                                         :id => '22' )

    should route(:delete, "/topics/555").to( :controller => 'messages',
                                             :action => 'destroy',
                                             :id => '555' )

    should route(:get, "/topics/22/quote").to( :controller => 'messages',
                                               :action => 'quote',
                                               :id => '22' )

    should route(:post, "/topics/555/reply").to( :controller => 'messages',
                                                 :action => 'reply',
                                                 :id => '555' )

    should route(:post, "/topics/2/preview").to( :controller => 'messages',
                                                 :action => 'preview',
                                                 :id => '2' )




  end

  context "news" do
    context "project scoped" do
      should route(:get, "/projects/567/news").to( :controller => 'news',
                                                   :action => 'index',
                                                   :project_id => '567' )

      should route(:get, "/projects/567/news.atom").to( :controller => 'news',
                                                        :action => 'index',
                                                        :format => 'atom',
                                                        :project_id => '567' )

      should route(:get, "/api/v1/projects/567/news.xml").to( :controller => 'api/v1/news',
                                                              :action => 'index',
                                                              :format => 'xml',
                                                              :project_id => '567' )

      should route(:get, "/api/v1/projects/567/news.json").to( :controller => 'api/v1/news',
                                                               :action => 'index',
                                                               :format => 'json',
                                                               :project_id => '567' )

      should route(:get, "/projects/567/news/new").to( :controller => 'news',
                                                       :action => 'new',
                                                       :project_id => '567' )

      should route(:post, "/projects/567/news").to( :controller => 'news',
                                                    :action => 'create',
                                                    :project_id => '567' )

      should route(:post, "/projects/567/news/preview").to( :controller => 'news/previews',
                                                            :action => 'create',
                                                            :project_id => '567')

    end

    should route(:get, "/news").to( :controller => 'news',
                                    :action => 'index' )

    should route(:get, "/news.atom").to( :controller => 'news',
                                         :action => 'index',
                                         :format => 'atom' )

    should route(:get, "/api/v1/news.xml").to( :controller => 'api/v1/news',
                                               :action => 'index',
                                               :format => 'xml' )

    should route(:get, "/api/v1/news.json").to( :controller => 'api/v1/news',
                                                :action => 'index',
                                                :format => 'json' )

    should route(:get, "/news/2").to( :controller => 'news',
                                      :action => 'show',
                                      :id => '2' )

    should route(:get, "/news/234").to( :controller => 'news',
                                        :action => 'show',
                                        :id => '234' )

    should route(:get, "/news/567/edit").to( :controller => 'news',
                                             :action => 'edit',
                                             :id => '567' )

    should route(:put, "/news/567").to( :controller => 'news',
                                        :action => 'update',
                                        :id => '567' )


    should route(:delete, "/news/567").to( :controller => 'news',
                                           :action => 'destroy',
                                           :id => '567' )

  end

  context "news/comments" do
    context "news scoped" do
      should route(:post, "/news/567/comments").to( :controller => 'news/comments',
                                                    :action => 'create',
                                                    :news_id => '567' )

    end

    should route(:delete, "/comments/15").to( :controller => 'news/comments',
                                              :action => 'destroy',
                                              :id => '15' )
  end

  context "news/previews" do
    context "news scoped" do
      should route(:post, "/news/567/preview").to( :controller => 'news/previews',
                                                   :action => 'create',
                                                   :news_id => '567' )
    end
  end

  context "project_enumerations" do
    context "project_scoped" do
      should route(:put, "/projects/64/enumerations").to( :controller => 'project_enumerations',
                                                          :action => 'update',
                                                          :project_id => '64' )

      should route(:delete, "/projects/64/enumerations").to( :controller => 'project_enumerations',
                                                             :action => 'destroy',
                                                             :project_id => '64' )
    end
  end

  context "timelogs" do
    should route(:get, "/time_entries").to( :controller => 'timelog',
                                            :action => 'index' )

    should route(:get, "/time_entries.csv").to( :controller => 'timelog',
                                                :action => 'index',
                                                :format => 'csv' )

    should route(:get, "/time_entries.atom").to( :controller => 'timelog',
                                                 :action => 'index',
                                                 :format => 'atom' )

    should route(:get, "/time_entries/new").to( :controller => 'timelog',
                                               :action => 'new' )

    should route(:get, "/time_entries/22/edit").to( :controller => 'timelog',
                                                    :action => 'edit',
                                                    :id => '22' )

    should route(:post, "/time_entries").to( :controller => 'timelog',
                                             :action => 'create' )

    should route(:put, "/time_entries/22").to( :controller => 'timelog',
                                               :action => 'update',
                                               :id => '22' )

    should route(:delete, "/time_entries/55").to( :controller => 'timelog',
                                                  :action => 'destroy',
                                                  :id => '55' )

    context "project scoped" do
      should route(:get, "/projects/567/time_entries").to( :controller => 'timelog',
                                                           :action => 'index',
                                                           :project_id => '567' )

      should route(:get, "/projects/567/time_entries.csv").to( :controller => 'timelog',
                                                               :action => 'index',
                                                               :project_id => '567',
                                                               :format => 'csv' )

      should route(:get, "/projects/567/time_entries.atom").to( :controller => 'timelog',
                                                                :action => 'index',
                                                                :project_id => '567',
                                                                :format => 'atom' )

      should route(:get, "/projects/567/time_entries/new").to( :controller => 'timelog',
                                                               :action => 'new',
                                                               :project_id => '567' )

      should route(:get, "/projects/567/time_entries/22/edit").to( :controller => 'timelog',
                                                                   :action => 'edit',
                                                                   :id => '22',
                                                                   :project_id => '567' )

      should route(:post, "/projects/567/time_entries").to( :controller => 'timelog',
                                                            :action => 'create',
                                                            :project_id => '567' )

      should route(:put, "/projects/567/time_entries/22").to( :controller => 'timelog',
                                                              :action => 'update',
                                                              :id => '22',
                                                              :project_id => '567' )

      should route(:delete, "/projects/567/time_entries/55").to( :controller => 'timelog',
                                                                 :action => 'destroy',
                                                                 :id => '55',
                                                                 :project_id => '567' )
    end
  end


  context "time_entries/reports" do
    should route(:get, "/time_entries/report").to( :controller => 'time_entries/reports',
                                                   :action => 'show' )
    should route(:get, "/projects/567/time_entries/report").to( :controller => 'time_entries/reports',
                                                                :action => 'show',
                                                                :project_id => '567' )

    should route(:get, "/projects/567/time_entries/report.csv").to( :controller => 'time_entries/reports',
                                                                    :action => 'show',
                                                                    :project_id => '567',
                                                                    :format => 'csv' )
  end

  context "users" do
    should route(:get, "/users").to( :controller => 'users',
                                     :action => 'index' )

    should route(:get, "/users.xml").to( :controller => 'users',
                                         :action => 'index',
                                         :format => 'xml' )

    should route(:get, "/users/44").to( :controller => 'users',
                                        :action => 'show',
                                        :id => '44' )

    should route(:get, "/users/44.xml").to( :controller => 'users',
                                            :action => 'show',
                                            :id => '44',
                                            :format => 'xml' )

    should route(:get, "/users/current").to( :controller => 'users',
                                             :action => 'show',
                                             :id => 'current' )

    should route(:get, "/users/current.xml").to( :controller => 'users',
                                                 :action => 'show',
                                                 :id => 'current',
                                                 :format => 'xml' )

    should route(:get, "/users/new").to( :controller => 'users',
                                         :action => 'new' )

    should route(:get, "/users/444/edit").to( :controller => 'users',
                                              :action => 'edit',
                                              :id => '444' )

    should route(:get, "/users/222/edit/membership").to( :controller => 'users',
                                                         :action => 'edit',
                                                         :id => '222',
                                                         :tab => 'membership' )

    should route(:post, "/users").to( :controller => 'users',
                                      :action => 'create' )

    should route(:post, "/users.xml").to( :controller => 'users',
                                          :action => 'create',
                                          :format => 'xml' )

    should route(:post, "/users/123/memberships").to( :controller => 'users',
                                                      :action => 'edit_membership',
                                                      :id => '123' )

    should route(:post, "/users/123/memberships/55").to( :controller => 'users',
                                                         :action => 'edit_membership',
                                                         :id => '123',
                                                         :membership_id => '55' )

    should route(:post, "/users/567/memberships/12/destroy").to( :controller => 'users',
                                                                 :action => 'destroy_membership',
                                                                 :id => '567',
                                                                 :membership_id => '12' )

    should route(:put, "/users/444").to( :controller => 'users',
                                         :action => 'update',
                                         :id => '444' )

    should route(:put, "/users/444.xml").to( :controller => 'users',
                                             :action => 'update',
                                             :id => '444',
                                             :format => 'xml' )
  end

  context "versions" do
    should route(:get, "/versions/1").to( :controller => 'versions',
                                          :action => 'show',
                                          :id => '1' )

    should route(:get, "/versions/1/edit").to( :controller => 'versions',
                                               :action => 'edit',
                                               :id => '1' )

    should route(:put, "/versions/1").to( :controller => 'versions',
                                          :action => 'update',
                                          :id => '1' )

    should route(:delete, "/versions/1").to( :controller => 'versions',
                                             :action => 'destroy',
                                             :id => '1' )

    should route(:get, "/versions/1/status_by").to( :controller => 'versions',
                                                    :action => 'status_by',
                                                    :id => '1' )

    context "project" do
      should route(:get, "/projects/foo/versions/new").to( :controller => 'versions',
                                                           :action => 'new',
                                                           :project_id => 'foo' )

      should route(:post, "/projects/foo/versions").to( :controller => 'versions',
                                                        :action => 'create',
                                                        :project_id => 'foo' )

      should route(:put, "/projects/foo/versions/close_completed").to( :controller => 'versions',
                                                                       :action => 'close_completed',
                                                                       :project_id => 'foo' )

      should route(:get, "/projects/foo/roadmap").to( :controller => 'versions',
                                                      :action => 'index',
                                                      :project_id => 'foo' )
    end
  end

  context "wiki (singular, project's pages)" do
    context "within project" do
      should route(:get, "/projects/567/wiki").to( :controller => 'wiki',
                                                   :action => 'show',
                                                   :project_id => '567' )

      should route(:get, "/projects/567/wiki/lalala").to( :controller => 'wiki',
                                                          :action => 'show',
                                                          :project_id => '567',
                                                          :id => 'lalala' )

      should route(:get, "/projects/567/wiki/my_page/edit").to( :controller => 'wiki',
                                                                :action => 'edit',
                                                                :project_id => '567',
                                                                :id => 'my_page' )

      should route(:get, "/projects/1/wiki/CookBook_documentation/history").to( :controller => 'wiki',
                                                                                :action => 'history',
                                                                                :project_id => '1',
                                                                                :id => 'CookBook_documentation' )
      should route(:get, "/projects/1/wiki/CookBook_documentation/diff").to( :controller => 'wiki',
                                                                             :action => 'diff',
                                                                             :project_id => '1',
                                                                             :id => 'CookBook_documentation' )

      should route(:get, "/projects/1/wiki/CookBook_documentation/diff/2").to( :controller => 'wiki',
                                                                               :action => 'diff',
                                                                               :project_id => '1',
                                                                               :id => 'CookBook_documentation',
                                                                               :version => '2' )

      should route(:get, "/projects/1/wiki/CookBook_documentation/diff/2/vs/1").to( :controller => 'wiki',
                                                                                    :action => 'diff',
                                                                                    :project_id => '1',
                                                                                    :id => 'CookBook_documentation',
                                                                                    :version => '2',
                                                                                    :version_from => '1')

      should route(:get, "/projects/1/wiki/CookBook_documentation/annotate/2").to( :controller => 'wiki',
                                                                                   :action => 'annotate',
                                                                                   :project_id => '1',
                                                                                   :id => 'CookBook_documentation',
                                                                                   :version => '2' )

      should route(:get, "/projects/22/wiki/ladida/rename").to( :controller => 'wiki',
                                                                :action => 'rename',
                                                                :project_id => '22',
                                                                :id => 'ladida' )

      should route(:get, "/projects/567/wiki/index").to( :controller => 'wiki',
                                                         :action => 'index',
                                                         :project_id => '567' )

      should route(:get, "/projects/567/wiki/date_index").to( :controller => 'wiki',
                                                              :action => 'date_index',
                                                              :project_id => '567' )

      should route(:get, "/projects/567/wiki/export").to( :controller => 'wiki',
                                                          :action => 'export',
                                                          :project_id => '567' )

      should route(:post, "/projects/567/wiki/CookBook_documentation/preview").to( :controller => 'wiki',
                                                                                   :action => 'preview',
                                                                                   :project_id => '567',
                                                                                   :id => 'CookBook_documentation' )
      should route(:put, "/projects/22/wiki/ladida/rename").to( :controller => 'wiki',
                                                                 :action => 'rename',
                                                                 :project_id => '22',
                                                                :id => 'ladida' )

      should route(:post, "/projects/22/wiki/ladida/protect").to( :controller => 'wiki',
                                                                  :action => 'protect',
                                                                  :project_id => '22',
                                                                  :id => 'ladida' )

      should route(:post, "/projects/22/wiki/ladida/add_attachment").to( :controller => 'wiki',
                                                                         :action => 'add_attachment',
                                                                         :project_id => '22',
                                                                         :id => 'ladida' )

      should route(:put, "/projects/567/wiki/my_page").to( :controller => 'wiki',
                                                           :action => 'update',
                                                           :project_id => '567',
                                                           :id => 'my_page' )

      should route(:delete, "/projects/22/wiki/ladida").to( :controller => 'wiki',
                                                            :action => 'destroy',
                                                            :project_id => '22',
                                                            :id => 'ladida' )
    end
  end

  context "wikis (plural, admin setup)" do
    should route(:get, "/projects/ladida/wiki/destroy").to( :controller => 'wikis',
                                                            :action => 'destroy',
                                                            :id => 'ladida')

    should route(:post, "/projects/ladida/wiki").to( :controller => 'wikis',
                                                     :action => 'edit',
                                                     :id => 'ladida')
    should route(:post, "/projects/ladida/wiki/destroy").to( :controller => 'wikis',
                                                             :action => 'destroy',
                                                             :id => 'ladida')
  end

  context "administration panel" do
    should route(:get, "/admin/projects").to( :controller => 'admin', :action => 'projects')
  end

  context "groups" do
    should route(:get, "/admin/groups").to( :controller => 'groups',
                                            :action => 'index' )

    should route(:get, "/admin/groups/new").to( :controller => 'groups',
                                                :action => 'new' )

    should route(:post, "/admin/groups").to( :controller => 'groups',
                                             :action => 'create' )

    should route(:get, "/admin/groups/4").to( :controller => 'groups',
                                              :action => 'show',
                                              :id => '4' )

    should route(:get, "/admin/groups/4/edit").to( :controller => 'groups',
                                                   :action => 'edit',
                                                   :id => '4' )

    should route(:put, "/admin/groups/4").to( :controller => 'groups',
                                              :action => 'update',
                                              :id => '4' )

    should route(:delete, "/admin/groups/4").to( :controller => 'groups',
                                                 :action => 'destroy',
                                                 :id => '4' )

    should route(:get, "/admin/groups/4/autocomplete_for_user").to( :controller => 'groups',
                                                                    :action => 'autocomplete_for_user',
                                                                    :id => '4' )

    should route(:post, "/admin/groups/4/members").to( :controller => 'groups',
                                                     :action => 'add_users',
                                                     :id => '4' )

    should route(:delete, "/admin/groups/4/members/5").to( :controller => 'groups',
                                                           :action => 'remove_user',
                                                           :id => '4',
                                                           :user_id => '5' )

    should route(:post, "/admin/groups/4/memberships").to( :controller => 'groups',
                                                           :action => 'create_memberships',
                                                           :id => '4' )

    should route(:put, "/admin/groups/4/memberships/5").to( :controller => 'groups',
                                                            :action => 'edit_membership',
                                                            :id => '4',
                                                            :membership_id => '5' )

    should route(:delete, "/admin/groups/4/memberships/5").to( :controller => 'groups',
                                                               :action => 'destroy_membership',
                                                               :id => '4',
                                                               :membership_id => '5' )
  end
end
