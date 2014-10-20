#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

shared_examples_for 'error response' do |code, id, message|
  it { expect(last_response.status).to eq(code) }

  describe 'response body' do
    subject { JSON.parse(last_response.body) }

    it { expect(subject['errorIdentifier']).to eq("urn:openproject-org:api:v3:errors:#{id}") }

    it 'includes an error description' do
      if message == :empty
        expect(subject['message']).to be_empty
      else
        expect(subject['message']).to include(message)
      end
    end
  end
end

shared_examples_for 'unauthenticated access' do
  it_behaves_like 'error response', 401,
                                    'Unauthorized',
                                    'You need to be authenticated to access this resource'
end

shared_examples_for 'unauthorized access' do
  it_behaves_like 'error response', 403,
                                    'MissingPermission',
                                    'You are not authorize to access this resource'
end

shared_examples_for 'not found' do |id, type|
  it_behaves_like 'error response', 404,
                                    'NotFound',
                                    "Couldn\'t find #{type} with id=#{id}"
end

shared_examples_for 'constraint violation' do |message|
  it_behaves_like 'error response', 422,
                                    'PropertyConstraintViolation',
                                    message
end
