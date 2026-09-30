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

RSpec.describe CustomValue::LinkStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) { instance_double(CustomValue, value:) }

  describe "#typed_value" do
    subject { instance.typed_value }

    context "when value is an https url with path" do
      let(:value) { "https://community.openproject.org/projects" }

      it { is_expected.to eq "https://community.openproject.org/projects" }
    end

    context "when value is an https url" do
      let(:value) { "https://community.openproject.org" }

      it { is_expected.to eq "https://community.openproject.org" }
    end

    context "when value is an http url with path" do
      let(:value) { "http://community.openproject.org/projects" }

      it { is_expected.to eq "http://community.openproject.org/projects" }
    end

    context "when value is an http url" do
      let(:value) { "http://community.openproject.org" }

      it { is_expected.to eq "http://community.openproject.org" }
    end

    context "when value is a domain with path" do
      let(:value) { "community.openproject.org/projects" }

      it { is_expected.to eq "community.openproject.org/projects" }
    end

    context "when value is a domain" do
      let(:value) { "community.openproject.org" }

      it { is_expected.to eq "community.openproject.org" }
    end

    context "when value is a custom schema url" do
      let(:value) { "random:hello" }

      it { is_expected.to eq "random:hello" }
    end

    context "when value is just a schema" do
      let(:value) { "https:" }

      it { is_expected.to eq "https:" }
    end

    context "when value is a path" do
      let(:value) { "/projects" }

      it { is_expected.to eq "/projects" }
    end

    context "when value is not a url" do
      let(:value) { "hello, world!" }

      it { is_expected.to eq "hello, world!" }
    end

    context "when value is blank" do
      let(:value) { "" }

      it { is_expected.to be_nil }
    end

    context "when value is nil" do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#formatted_value" do
    subject { instance.formatted_value }

    context "when value is an https url with path" do
      let(:value) { "https://community.openproject.org/projects" }

      it { is_expected.to eq "https://community.openproject.org/projects" }
    end

    context "when value is an https url" do
      let(:value) { "https://community.openproject.org" }

      it { is_expected.to eq "https://community.openproject.org" }
    end

    context "when value is an http url with path" do
      let(:value) { "http://community.openproject.org/projects" }

      it { is_expected.to eq "http://community.openproject.org/projects" }
    end

    context "when value is an http url" do
      let(:value) { "http://community.openproject.org" }

      it { is_expected.to eq "http://community.openproject.org" }
    end

    context "when value is a domain with path" do
      let(:value) { "community.openproject.org/projects" }

      it { is_expected.to eq "community.openproject.org/projects" }
    end

    context "when value is a domain" do
      let(:value) { "community.openproject.org" }

      it { is_expected.to eq "community.openproject.org" }
    end

    context "when value is a custom schema url" do
      let(:value) { "random:hello" }

      it { is_expected.to eq "random:hello" }
    end

    context "when value is just a schema" do
      let(:value) { "https:" }

      it { is_expected.to eq "https:" }
    end

    context "when value is a path" do
      let(:value) { "/projects" }

      it { is_expected.to eq "/projects" }
    end

    context "when value is not a url" do
      let(:value) { "hello, world!" }

      it { is_expected.to eq "hello, world!" }
    end

    context "when value is blank" do
      let(:value) { "" }

      it { is_expected.to eq "" }
    end

    context "when value is nil" do
      let(:value) { nil }

      it { is_expected.to eq "" }
    end
  end

  describe "#parse_value" do
    subject { instance.parse_value(input) }

    let(:custom_value) { instance_double(CustomValue) }

    context "when value is an https url with path" do
      let(:input) { "https://community.openproject.org/projects" }

      it { is_expected.to eq "https://community.openproject.org/projects" }
    end

    context "when value is an https url" do
      let(:input) { "https://community.openproject.org" }

      it { is_expected.to eq "https://community.openproject.org" }
    end

    context "when value is an http url with path" do
      let(:input) { "http://community.openproject.org/projects" }

      it { is_expected.to eq "http://community.openproject.org/projects" }
    end

    context "when value is an http url" do
      let(:input) { "http://community.openproject.org" }

      it { is_expected.to eq "http://community.openproject.org" }
    end

    context "when value is a domain with path" do
      let(:input) { "community.openproject.org/projects" }

      it { is_expected.to eq "http://community.openproject.org/projects" }
    end

    context "when value is a domain" do
      let(:input) { "community.openproject.org" }

      it { is_expected.to eq "http://community.openproject.org" }
    end

    context "when value is a custom schema url" do
      let(:input) { "random:hello" }

      it { is_expected.to eq "random:hello" }
    end

    context "when value is just a schema" do
      let(:input) { "https:" }

      it { is_expected.to be_nil }
    end

    context "when value is a path" do
      let(:input) { "/projects" }

      it { is_expected.to eq "/projects" }
    end

    context "when value is not a url" do
      let(:input) { "hello, world!" }

      it { is_expected.to eq "hello, world!" }
    end

    context "when value is blank" do
      let(:input) { "" }

      it { is_expected.to eq "" }
    end

    context "when value is nil" do
      let(:input) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    context "when value is an https url with path" do
      let(:value) { "https://community.openproject.org/projects" }

      it { is_expected.to be_nil }
    end

    context "when value is an https url" do
      let(:value) { "https://community.openproject.org" }

      it { is_expected.to be_nil }
    end

    context "when value is an http url with path" do
      let(:value) { "http://community.openproject.org/projects" }

      it { is_expected.to be_nil }
    end

    context "when value is an http url" do
      let(:value) { "http://community.openproject.org" }

      it { is_expected.to be_nil }
    end

    context "when value is a domain with path" do
      let(:value) { "community.openproject.org/projects" }

      it { is_expected.to be_nil }
    end

    context "when value is a domain" do
      let(:value) { "community.openproject.org" }

      it { is_expected.to be_nil }
    end

    context "when value is a custom schema url" do
      let(:value) { "random:hello" }

      it { is_expected.to be_nil }
    end

    context "when value is just a schema" do
      let(:value) { "https:" }

      it { is_expected.to eq :invalid_url }
    end

    context "when value is a path" do
      let(:value) { "/projects" }

      it { is_expected.to eq :invalid_url }
    end

    context "when value is not a url" do
      let(:value) { "hello, world!" }

      it { is_expected.to eq :invalid_url }
    end

    context "when value is blank" do
      let(:value) { "" }

      it { is_expected.to eq :invalid_url }
    end

    context "when value is nil" do
      let(:value) { nil }

      it { is_expected.to eq :invalid_url }
    end
  end
end
