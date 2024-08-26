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

RSpec.shared_examples_for "successful response" do |code = 200|
  it "has the status code #{code}" do
    expect(last_response).to have_http_status(code)
  end

  it "has a HAL+JSON Content-Type" do
    expected_content_type = "application/hal+json; charset=utf-8"
    expect(last_response.headers).to include "Content-Type"
    expect(last_response.headers["Content-Type"].downcase).to eql expected_content_type
  end
end

RSpec.shared_examples_for "successful no content response" do |code = 204|
  it "has the status code #{code}" do
    expect(last_response).to have_http_status(code)
  end
end

RSpec.shared_examples_for "redirect response" do |code = 303|
  let(:location) { "" }

  it "has the status code #{code}" do
    expect(last_response).to have_http_status(code)
  end

  it "redirects to expected location" do
    expect(last_response.headers["Location"]).to eq(location)
  end
end

RSpec.shared_examples_for "error response" do |code, id, provided_message = nil|
  let(:expected_message) do
    provided_message || message
  end

  it "has the status code #{code}" do
    expect(last_response).to have_http_status(code)
  end

  it "has a HAL+JSON Content-Type" do
    expected_content_type = "application/hal+json; charset=utf-8"
    expect(last_response.headers).to include "Content-Type"
    expect(last_response.headers["Content-Type"].downcase).to eql expected_content_type
  end

  describe "response body" do
    subject { JSON.parse(last_response.body) }

    describe "errorIdentifier" do
      it { expect(subject["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:#{id}") }
    end

    describe "message" do
      it { expect(subject["message"]).to include(expected_message) }

      it "includes punctuation" do
        expect(subject["message"]).to match(/(\.|\?|!)\z/)
      end
    end
  end
end

RSpec.shared_examples_for "invalid render context" do |message|
  it_behaves_like "error response",
                  400,
                  "InvalidRenderContext",
                  message
end

RSpec.shared_examples_for "invalid request body" do |message|
  it_behaves_like "error response",
                  400,
                  "InvalidRequestBody",
                  message
end

RSpec.shared_examples_for "invalid resource link" do |message|
  it_behaves_like "error response",
                  422,
                  "ResourceTypeMismatch",
                  message
end

RSpec.shared_examples_for "unsupported content type" do |message|
  it_behaves_like "error response",
                  415,
                  "TypeNotSupported",
                  message
end

RSpec.shared_examples_for "parse error" do |details|
  it_behaves_like "invalid request body",
                  I18n.t("api_v3.errors.invalid_json")

  it "shows the given details" do
    if details
      expect(last_response.body).to be_json_eql(details.to_json)
                                      .at_path("_embedded/details/parseError")
    end
  end
end

RSpec.shared_examples_for "invalid filters" do
  it_behaves_like "error response",
                  400,
                  "InvalidQuery",
                  I18n.t("api_v3.errors.missing_or_malformed_parameter", parameter: "filters")
end

RSpec.shared_examples_for "unauthenticated access" do
  it_behaves_like "error response",
                  401,
                  "Unauthenticated",
                  I18n.t("api_v3.errors.code_401")
end

RSpec.shared_examples_for "unauthorized access" do
  it_behaves_like "error response",
                  403,
                  "MissingPermission",
                  I18n.t("api_v3.errors.code_403")
end

RSpec.shared_examples_for "not found" do |message = I18n.t("api_v3.errors.code_404")|
  include_examples "error response",
                   404,
                   "NotFound",
                   message
end

RSpec.shared_examples_for "forbidden response based on login_required" do
  context "when login_required", with_settings: { login_required: true } do
    it_behaves_like "unauthenticated access"
  end

  context "when not login_required", with_settings: { login_required: false } do
    it_behaves_like "unauthorized access"
  end
end

RSpec.shared_examples_for "not found response based on login_required" do |message = I18n.t("api_v3.errors.code_404")|
  context "when login_required", with_settings: { login_required: true } do
    it_behaves_like "unauthenticated access"
  end

  context "when not login_required", with_settings: { login_required: false } do
    it_behaves_like "not found", message
  end
end

RSpec.shared_examples_for "param validation error" do
  subject { JSON.parse(last_response.body) }

  it "results in a validation error" do
    expect(last_response).to have_http_status(:bad_request)
    expect(subject["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:BadRequest")
    expect(subject["message"]).to match /Bad request: .+? is invalid/
  end
end

RSpec.shared_examples_for "update conflict" do
  it_behaves_like "error response",
                  409,
                  "UpdateConflict",
                  I18n.t("api_v3.errors.code_409")
end

RSpec.shared_examples_for "constraint violation" do
  it_behaves_like "error response",
                  422,
                  "PropertyConstraintViolation"
end

RSpec.shared_examples_for "format error" do |message|
  it_behaves_like "error response",
                  422,
                  "PropertyFormatError",
                  message
end

RSpec.shared_examples_for "missing property" do |message|
  it_behaves_like "error response",
                  422,
                  "PropertyMissingError",
                  message
end

RSpec.shared_examples_for "read-only violation" do |attribute, model, attribute_message = nil|
  describe "details" do
    subject { JSON.parse(last_response.body)["_embedded"]["details"] }

    it { expect(subject["attribute"]).to eq(attribute) }
  end

  message = [
    attribute_message || model.human_attribute_name(attribute),
    I18n.t("activerecord.errors.messages.error_readonly")
  ].join(" ")
  it_behaves_like "error response",
                  422,
                  "PropertyIsReadOnly",
                  message
end

RSpec.shared_examples_for "multiple errors" do |code, _message|
  it_behaves_like "error response",
                  code,
                  "MultipleErrors",
                  I18n.t("api_v3.errors.multiple_errors")
end

RSpec.shared_examples_for "multiple errors of the same type" do |error_count, id|
  subject { JSON.parse(last_response.body)["_embedded"]["errors"] }

  it { expect(subject.count).to eq(error_count) }

  it "has child errors of expected type" do
    subject.each do |error|
      expect(error["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:#{id}")
    end
  end
end

RSpec.shared_examples_for "multiple errors of the same type with details" do |expected_details, expected_detail_values|
  let(:errors) { JSON.parse(last_response.body)["_embedded"]["errors"] }
  let(:details) do
    errors.each_with_object([]) { |error, l| l << error["_embedded"]["details"] }.compact
  end

  subject do
    details.inject({}) do |h, d|
      h.merge(d) { |_, old, new| Array(old) + Array(new) }
    end
  end

  it { expect(subject.keys).to match_array(Array(expected_details)) }

  it "contains all expected values" do
    Array(expected_details).each do |detail|
      expect(subject[detail]).to match_array(Array(expected_detail_values[detail]))
    end
  end
end

RSpec.shared_examples_for "multiple errors of the same type with messages" do
  let(:errors) { JSON.parse(last_response.body)["_embedded"]["errors"] }
  let(:actual_messages) do
    errors.each_with_object([]) { |error, l| l << error["message"] }.compact
  end

  before do
    unless defined?(message)
      raise "Need to have 'message' defined to state\
             which message is expected".squish
    end
  end

  it { expect(actual_messages).to match_array(Array(message)) }
end
