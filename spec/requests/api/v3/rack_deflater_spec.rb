#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Rack::Deflater, type: :request do
  include API::V3::Utilities::PathHelper

  let(:text) { 'text' }

  it 'produces an identical eTag whether content is deflated or not' do
    # Using the api_v3_paths.configuaration because of the endpoint's simplicity.
    # It could be any endpoint really.
    get api_v3_paths.configuration

    expect(response.headers['Content-Encoding']).to be_nil

    etag = response.headers['Etag']
    content_length = response.headers['Content-Length'].to_i

    get api_v3_paths.configuration,
        params: {},
        headers: { 'Accept-Encoding' => 'gzip' }

    expect(response.headers['Etag']).to eql etag
    expect(response.headers['Content-Length'].to_i).to_not eql content_length
    expect(response.headers['Content-Encoding']).to eql 'gzip'
  end
end
