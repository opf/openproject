#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe WatchersController, type: :routing do
  shared_examples_for 'watched model routes' do
    before do
      expect(OpenProject::Acts::Watchable::Routes).to receive(:matches?).and_return(true)
    end

    it 'should connect POST /:object_type/:object_id/watch to watchers#watch' do
      expect(post("/#{type}/1/watch")).to route_to(controller: 'watchers',
                                                   action: 'watch',
                                                   object_type: type,
                                                   object_id: '1')
    end

    it 'should connect DELETE /:object_type/:id/unwatch to watchers#unwatch' do

      expect(delete("/#{type}/1/unwatch")).to route_to(controller: 'watchers',
                                                       action: 'unwatch',
                                                       object_type: type,
                                                       object_id: '1')
    end

    it 'should connect GET /:object_type/:id/watchers/new to watchers#new' do
      expect(get("/#{type}/1/watchers/new")).to route_to(controller: 'watchers',
                                                         action: 'new',
                                                         object_type: type,
                                                         object_id: '1')
    end

    it 'should connect POST /:object_type/:object_id/watchers to watchers#create' do
      expect(post("/#{type}/1/watch")).to route_to(controller: 'watchers',
                                                   action: 'watch',
                                                   object_type: type,
                                                   object_id: '1')
    end
  end

  ['issues', 'news', 'boards', 'messages', 'wikis', 'wiki_pages'].each do |type|
    describe "routing #{type} watches" do
      let(:type) { type }

      it_should_behave_like 'watched model routes'
    end
  end

  it 'should connect DELETE watchers/:id to watchers#destroy' do
    expect(delete('/watchers/1')).to route_to(controller: 'watchers',
                                              action: 'destroy',
                                              id: '1')
  end
end
