# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe UriTemplate do
  let(:uri_template) { described_class.new(template_string) }
  let(:template_string) { "https://openproject.local/statuses/{id}" }
  let(:uri) { "https://openproject.local/statuses/123" }

  describe "initializer" do
    subject { uri_template }

    it "raises no errors" do
      subject
    end

    context "when passing a nil string" do
      let(:template_string) { nil }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "template_string can't be nil")
      end
    end
  end

  describe "#match?" do
    subject { uri_template.match?(uri) }

    context "when the URL matches" do
      it { is_expected.to be_truthy }
    end

    context "when the URL is different" do
      let(:uri) { "https://openproject.local/types/123" }

      it { is_expected.to be_falsey }
    end

    context "when the URL would leave a variable empty" do
      let(:uri) { "https://openproject.local/statuses/" }

      it { is_expected.to be_falsey }
    end

    context "when the template placeholder contains unsupported characters" do
      let(:template_string) { "https://openproject.local/statuses/{the id}" }

      it { is_expected.to be_falsey }
    end
  end

  describe "#parse" do
    subject { uri_template.parse(uri) }

    context "when the URL matches" do
      it { is_expected.to eq({ id: "123" }) }
    end

    context "when the URL is different" do
      let(:uri) { "https://openproject.local/types/123" }

      it { is_expected.to be_nil }
    end

    context "when expanded variable contains dashes" do
      let(:uri) { "https://openproject.local/statuses/red-alert" }

      it { is_expected.to eq({ id: "red-alert" }) }
    end

    context "when templating multiple variables" do
      let(:template_string) { "https://openproject.local/statuses/{id}/something/{thing}" }
      let(:uri) { "https://openproject.local/statuses/123/something/unicorn" }

      it { is_expected.to eq({ id: "123", thing: "unicorn" }) }
    end
  end
end
