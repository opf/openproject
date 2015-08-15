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
require 'rack/test'

describe 'removed api v1', type: :request do
  include Rack::Test::Methods

  subject(:response) { last_response }

  context 'issues' do
    it 'should return a 410 for GET /api/v1/issues' do
      get '/api/v1/issues'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/projects/:id/issues' do
      get '/api/v1/issues'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/issues/:id' do
      get '/api/v1/issues/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/project/:id/issues/:id' do
      get '/api/v1/projects/5/issues/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for POST /api/v1/projects/:id/issues' do
      post '/api/v1/projects/5/issues'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/issues/:id' do
      put '/api/v1/issues/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/projects/:id/issues' do
      put '/api/v1/projects/5/issues'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for DELETE /api/v1/issues/:id' do
      delete '/api/v1/issues/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for DELETE /api/v1/projects/:id/issues/:id' do
      delete '/api/v1/projects/5/issues/5'
      expect(subject.status).to eql(410)
    end
  end

  context 'news' do
    it 'should return a 410 for GET /api/v1/news' do
      get '/api/v1/news'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/projects/:id/news' do
      get '/api/v1/project/5/news'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/news/:id' do
      get '/api/v1/news/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/projects/:id/news/:id' do
      get '/api/v1/projects/5/news/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for POST /api/v1/news' do
      post '/api/v1/news'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for POST /api/v1/projects/:id/news' do
      post '/api/v1/projects/5/news'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/news/:id' do
      put '/api/v1/news/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/projects/:id/news/:id' do
      put '/api/v1/projects/5/news/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for DELETE /api/v1/news/:id' do
      delete '/api/v1/news/5'
      expect(subject.status).to eql(410)
    end
  end

  context 'projects' do
    it 'should return a 410 for GET /api/v1/projects' do
      get '/api/v1/projects'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/projects/:id' do
      get '/api/v1/projects/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/projects/level_list' do
      get '/api/v1/projects/level_list'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for POST /api/v1/projects' do
      post '/api/v1/projects'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/projects' do
      put '/api/v1/projects'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for DELETE /api/v1/projects/:id' do
      delete '/api/v1/projects/5'
      expect(subject.status).to eql(410)
    end
  end

  context 'timelogs' do
    it 'should return a 410 for GET /api/v1/timelogs' do
      get '/api/v1/timelogs'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/timelogs/:id' do
      get '/api/v1/timelogs/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/timelogs/:id' do
      put '/api/v1/timelogs/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for DELETE /api/v1/timelogs/:id' do
      delete '/api/v1/timelogs/5'
      expect(subject.status).to eql(410)
    end
  end

  context 'users' do
    it 'should return a 410 for GET /api/v1/users' do
      get '/api/v1/users'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for GET /api/v1/users/:id' do
      get '/api/v1/users/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for PUT /api/v1/users/:id' do
      put '/api/v1/users/5'
      expect(subject.status).to eql(410)
    end

    it 'should return a 410 for DELETE /api/v1/users/:id' do
      delete '/api/v1/users/5'
      expect(subject.status).to eql(410)
    end
  end
end
