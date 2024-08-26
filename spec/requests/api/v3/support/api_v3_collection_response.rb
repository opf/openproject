#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.shared_examples_for "API V3 collection response" do |total, count, element_type, collection_type = "Collection"|
  subject { last_response.body }

  # If an array of elements is provided, those elements are expected
  # to be embedded in the _embedded/elements section in the order provided.
  # Only the id of the element is checked for.
  let(:elements) { nil }

  # Allow input to pass a proc to avoid counting before the example
  # context
  let(:total_number) do
    if total.is_a? Proc
      total.call
    else
      total
    end
  end

  let(:count_number) do
    if count.is_a? Proc
      count.call
    else
      count
    end
  end

  # Allow overriding the expect HTTP status code
  let(:expected_status_code) { 200 }

  it "returns a collection successfully" do
    aggregate_failures do
      expect(last_response).to have_http_status(expected_status_code)
      errors = JSON.parse(subject).dig("_embedded", "errors")&.map { _1["message"] }
      expect(errors).to eq([]) if errors # make errors visible in console if any
    end
  end

  it "contains all elements" do
    aggregate_failures do
      expect(subject).to be_json_eql(collection_type.to_json).at_path("_type")
      expect(subject).to be_json_eql(count_number.to_json).at_path("count")
      expect(subject).to be_json_eql(total_number.to_json).at_path("total")
      expect(subject).to have_json_size(count_number).at_path("_embedded/elements")

      if element_type && count_number > 0
        expect(subject).to be_json_eql(element_type.to_json).at_path("_embedded/elements/0/_type")
      end

      elements&.each_with_index do |element, index|
        expect(subject).to be_json_eql(element.id.to_json).at_path("_embedded/elements/#{index}/id")
      end
    end
  end
end
