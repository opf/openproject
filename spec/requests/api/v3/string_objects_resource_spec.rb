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

describe 'API v3 String Objects resource' do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  describe 'string_objects' do
    subject(:response) { last_response }

    let(:path) { api_v3_paths.string_object 'foo bar' }

    before do
      get path
    end

    it 'is successful' do
      expect(subject.status).to eql(200)
    end

    it 'returns the value' do
      expect(subject.body).to be_json_eql('foo bar'.to_json).at_path('value')
    end

    context 'empty string' do
      let(:path) { api_v3_paths.string_object '' }

      it 'is successful' do
        expect(subject.status).to eql(200)
      end

      it 'returns the value' do
        expect(subject.body).to be_json_eql(''.to_json).at_path('value')
      end
    end

    context 'nil string' do
      let(:path) { '/api/v3/string_objects?value' }

      it 'is successful' do
        expect(subject.status).to eql(200)
      end

      it 'returns the empty string' do
        expect(subject.body).to be_json_eql(''.to_json).at_path('value')
      end
    end
  end
end
