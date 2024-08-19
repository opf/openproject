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

RSpec.shared_examples_for "bcf api successful response" do
  def expect_identical_without_time(subject, expected_body) # rubocop:disable Metrics/PerceivedComplexity
    body = Array.wrap(JSON.parse(subject.body))
    expected = Array.wrap(expected_body)
    expect(body.size).to eql(expected.size)

    expected.each_with_index do |expected_item, index|
      subject_body = body[index]

      expected_item.stringify_keys!
      # Remove date strings and compare separately
      subject_modified_date = subject_body.delete("modified_date")&.to_time
      expected_modified_date = expected_item.delete("modified_date")&.to_time

      if expected_modified_date
        expect(subject_modified_date).to equal_time_without_usec(expected_modified_date)
      else
        expect(subject_modified_date).to be_nil
      end

      subject_created_date = subject_body.delete("date")&.to_time
      expected_created_date = expected_item.delete("date")&.to_time

      if expected_created_date
        expect(subject_created_date).to equal_time_without_usec(expected_created_date)
      else
        expect(subject_created_date).to be_nil
      end

      expect(subject_body.to_json).to be_json_eql(expected_item.to_json)
    end
  end

  it "responds correctly with the expected body", :aggregate_failures do
    expect(subject.status)
      .to eql(defined?(expected_status) ? expected_status : 200)

    if expected_body.nil?
      expect(subject.body).to be_json_eql(expected_body.to_json)
    else
      expect_identical_without_time(subject, expected_body)
    end

    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8" unless defined?(no_content)
  end
end

RSpec.shared_examples_for "bcf api successful response expectation" do
  it "responds correctly with the expected body", :aggregate_failures do
    expect(subject.status).to eq 200

    instance_exec(subject.body, &expectations)

    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8"
  end
end

RSpec.shared_examples_for "bcf api not found response" do
  let(:expect404) do
    { message: "The requested resource could not be found." }
  end

  it "responds 404 NOT FOUND", :aggregate_failures do
    expect(subject.status).to eq 404
    expect(subject.body).to be_json_eql(expect404.to_json)
    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8"
  end
end

RSpec.shared_examples_for "bcf api method not allowed response" do
  let(:expect405) { "405 Not Allowed" }

  it "responds 405 METHOD NOT ALLOWED", :aggregate_failures do
    expect(subject.status).to eq 405
    expect(subject.body).to eql(expect405)
    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8"
  end
end

RSpec.shared_examples_for "bcf api not allowed response" do
  let(:expect403) do
    { message: "You are not authorized to access this resource." }
  end

  it "responds 403 NOT ALLOWED", :aggregate_failures do
    expect(subject.status).to eq 403
    expect(subject.body).to be_json_eql(expect403.to_json)
    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8"
  end
end

RSpec.shared_examples_for "bcf api unprocessable response" do
  let(:expect422) do
    { message: }
  end

  it "responds 422 UNPROCESSABLE ENTITY", :aggregate_failures do
    expect(subject.status).to eq 422
    expect(subject.body).to be_json_eql(expect422.to_json)
    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8"
  end
end

RSpec.shared_examples_for "bcf api not implemented response" do
  it "responds 501 not implemented", :aggregate_failures do
    expect(subject.status).to be 501

    expected = {
      message: expected_message
    }

    expect(subject.body).to be_json_eql(expected.to_json)
    expect(subject.headers["Content-Type"]).to eql "application/json; charset=utf-8"
  end
end
