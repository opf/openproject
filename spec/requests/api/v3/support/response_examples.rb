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

    describe 'message' do
      it { expect(subject['message']).to include(message) }

      it 'includes punctuation' do
        expect(subject['message']).to match(/(\.|\?|\!)\z/)
      end
    end
  end
end

shared_examples_for 'unauthenticated access' do
  it_behaves_like 'error response',
                  401,
                  'MissingPermission',
                  'You need to be authenticated to access this resource'
end

shared_examples_for 'unauthorized access' do
  it_behaves_like 'error response',
                  403,
                  'MissingPermission',
                  'You are not authorize to access this resource'
end

shared_examples_for 'not found' do |id, type|
  it_behaves_like 'error response',
                  404,
                  'NotFound',
                  "Couldn\'t find #{type} with id=#{id}"
end

shared_examples_for 'constraint violation' do |message|
  it_behaves_like 'error response',
                  422,
                  'PropertyConstraintViolation',
                  message
end

shared_examples_for 'read-only violation' do |attribute|
  describe 'details' do
    subject { JSON.parse(last_response.body)['_embedded']['details'] }

    it { expect(subject['attribute']).to eq(attribute) }
  end

  it_behaves_like 'error response',
                  422,
                  'PropertyIsReadOnly',
                  'You must not write a read-only attribute'
end

shared_examples_for 'multiple errors' do |code, message|
  it_behaves_like 'error response', code, 'MultipleErrors', message
end

shared_examples_for 'multiple errors of the same type' do |error_count, id|
  subject { JSON.parse(last_response.body)['_embedded']['errors'] }

  it { expect(subject.count).to eq(error_count) }

  it 'has child errors of expected type' do
    subject.each do |error|
      expect(error['errorIdentifier']).to eq("urn:openproject-org:api:v3:errors:#{id}")
    end
  end
end

shared_examples_for 'multiple errors of the same type with details' do |expected_details, expected_detail_values|
  let(:errors) { JSON.parse(last_response.body)['_embedded']['errors'] }
  let(:details) { errors.each_with_object([]) { |error, l| l << error['_embedded']['details'] }.compact }

  subject do
    details.inject({}) do |h, d|
      h.merge(d) { |_, old, new| Array(old) + Array(new) }
    end
  end

  it { expect(subject.keys).to match_array(Array(expected_details)) }

  it 'contains all expected values' do
    Array(expected_details).each do |detail|
      expect(subject[detail]).to match_array(Array(expected_detail_values[detail]))
    end
  end
end

shared_examples_for 'multiple errors of the same type with messages' do |expected_messages|
  let(:errors) { JSON.parse(last_response.body)['_embedded']['errors'] }
  let(:messages) { errors.each_with_object([]) { |error, l| l << error['message'] }.compact }

  it { expect(messages).to match_array(Array(expected_messages)) }
end
