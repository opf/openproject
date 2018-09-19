#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe AttachmentsController, 'routing', type: :routing do
  it {
    is_expected.to route(:get, '/attachments/1').to(controller: 'attachments',
                                                    action: 'download',
                                                    id: '1')
  }
  it {
    is_expected.to route(:get, '/attachments/1/filename.ext').to(controller: 'attachments',
                                                                 action: 'download',
                                                                 id: '1',
                                                                 filename: 'filename.ext')
  }

  it {
    is_expected.to route(:delete, '/attachments/1').to(controller: 'attachments',
                                                       action: 'destroy',
                                                       id: '1')
  }
end

describe AttachmentsController, 'routing', type: :request do
  describe 'for backwards compatibility' do
    it 'redirects /attachments/download with filename to attachments#download' do
      get '/attachments/download/42/foo.png'

      expect(last_response).to be_redirect
      expect(last_response.location).to end_with '/attachments/42/foo.png'
    end

    it 'redirects /attachments/download without filename to attachments#download' do
      get '/attachments/download/42'

      expect(last_response).to be_redirect
      expect(last_response.location).to end_with '/attachments/42'
    end
  end
end
