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

describe WatchersController do
  shared_examples_for "watched model routes" do
    before do
      OpenProject::Acts::Watchable::Routes.should_receive(:matches?).and_return(true)
    end


    it "should connect POST /:object_type/:object_id/watch to watchers#watch" do
      post("/#{type}/1/watch").should route_to( :controller => 'watchers',
                                                :action => 'watch',
                                                :object_type => type,
                                                :object_id => '1' )
    end

    it "should connect DELETE /:object_type/:id/unwatch to watchers#unwatch" do

      delete("/#{type}/1/unwatch").should route_to( :controller => 'watchers',
                                                    :action => 'unwatch',
                                                    :object_type => type,
                                                    :object_id => '1' )
    end

    it "should connect GET /:object_type/:id/watchers/new to watchers#new" do
      get("/#{type}/1/watchers/new").should route_to( :controller => 'watchers',
                                                      :action => 'new',
                                                      :object_type => type,
                                                      :object_id => '1' )
    end

    it "should connect POST /:object_type/:object_id/watchers to watchers#create" do
      post("/#{type}/1/watch").should route_to( :controller => 'watchers',
                                                :action => 'watch',
                                                :object_type => type,
                                                :object_id => '1' )
    end
  end

  ['issues', 'news', 'boards', 'messages', 'wikis', 'wiki_pages'].each do |type|
    describe "routing #{type} watches" do
      let(:type) { type }

      it_should_behave_like "watched model routes"
    end
  end

  it "should connect DELETE watchers/:id to watchers#destroy" do
    delete("/watchers/1").should route_to( :controller => 'watchers',
                                           :action => 'destroy',
                                           :id => '1' )
  end
end
