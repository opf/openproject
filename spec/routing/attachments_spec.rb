#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'attachments routing', type: :request do
  describe 'for backwards compatibility' do
    it 'redirects GET attachments/:id to api v3 attachments/:id/content' do
      get "/attachments/1"
      expect(last_response).to be_redirect
      expect(last_response.location).to end_with("/api/v3/attachments/1/content")
    end

    it 'redirects GET attachments/:id/filename.ext to api v3 attachments/:id/content' do
      get "/attachments/1/filename.ext"
      expect(last_response).to be_redirect
      expect(last_response.location).to end_with("/api/v3/attachments/1/content")
    end

    it 'redirects DELETE attachments/:id to api v3 attachments/:id' do
      delete "/attachments/1"
      expect(last_response).to be_redirect
      expect(last_response.location).to end_with("/api/v3/attachments/1")
    end

    it 'redirects GET /attachments/download with filename to attachments#download' do
      get '/attachments/download/42/foo.png'

      expect(last_response).to be_redirect
      expect(last_response.location).to end_with '/attachments/42/foo.png'
    end

    it 'redirects GET /attachments/download without filename to attachments#download' do
      get '/attachments/download/42'

      expect(last_response).to be_redirect
      expect(last_response.location).to end_with '/attachments/42'
    end
  end
end
