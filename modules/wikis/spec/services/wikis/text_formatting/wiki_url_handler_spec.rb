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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Wikis::TextFormatting::WikiUrlHandler do
  let(:handler) { described_class.new }
  let(:url) { URI.parse("https://example.com") }

  let(:provider) { create(:internal_wiki_provider) }
  let(:auth_strategy) { instance_double(Wikis::Adapters::Providers::Internal::Authentication::UserBound, call: nil) }
  let(:query) { instance_double(Wikis::Adapters::BaseQuery, call: query_result) }
  let(:query_result) { Success(page_info) }
  let(:page_info) { Wikis::Adapters::Results::PageInfo.new(identifier: "abc", provider:, title: "A page", href: url.to_s) }

  before do
    provider

    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Wikis::Provider).to receive(:auth_strategy_for).and_return(Success(auth_strategy))
    allow_any_instance_of(Wikis::Provider).to receive(:resolve).with("queries.page_info_for_url").and_return(query)
    # rubocop:enable RSpec/AnyInstance
  end

  describe "#match?" do
    subject { handler.match?(url) }

    it { is_expected.to be_truthy }

    it "passes the URL to the query" do
      subject
      expect(query).to have_received(:call).with(input_data: having_attributes(url: url.to_s), auth_strategy:)
    end

    context "when the provider finds no page" do
      let(:query_result) { Failure(Wikis::Adapters::Results::Error.new(code: :not_found, source: self)) }

      it { is_expected.to be_falsey }
    end

    context "when the provider returns an unexpected error" do
      let(:query_result) { Failure(Wikis::Adapters::Results::Error.new(code: :banana, source: self)) }

      it { is_expected.to be_falsey }
    end

    context "when a matching provider is disabled" do
      let(:provider) { create(:internal_wiki_provider, enabled: false) }

      it { is_expected.to be_falsey }
    end

    context "when a non-https URL is passed" do
      let(:url) { URI.parse("data:,Hello%2C%20World%21") }

      it { is_expected.to be_falsey }
    end

    context "when asking for two different URLs" do
      let(:second_url) { URI.parse("https://other.example.com") }

      it "calls the provider query twice" do
        subject
        handler.match?(second_url)

        expect(query).to have_received(:call).twice
        expect(query).to have_received(:call).with(input_data: having_attributes(url: url.to_s), auth_strategy:)
        expect(query).to have_received(:call).with(input_data: having_attributes(url: second_url.to_s), auth_strategy:)
      end
    end

    context "when asking for the same URL twice" do
      it "calls the provider query once" do
        subject
        handler.match?(url)

        expect(query).to have_received(:call).once
      end
    end
  end

  describe "#html_for" do
    subject { handler.html_for(url) }

    it "returns a formatted link to the URL" do
      component = Capybara.string(subject)
      expect(component).to have_css(".op-inline-macro")
      expect(component).to have_css(%{a[href="#{url}"]})
    end

    context "when the provider finds no page" do
      let(:query_result) { Failure(Wikis::Adapters::Results::Error.new(code: :not_found, source: self)) }

      it { is_expected.to be_nil }
    end

    context "when the provider returns an unexpected error" do
      let(:query_result) { Failure(Wikis::Adapters::Results::Error.new(code: :banana, source: self)) }

      it { is_expected.to be_nil }
    end

    context "when a matching provider is disabled" do
      let(:provider) { create(:internal_wiki_provider, enabled: false) }

      it { is_expected.to be_nil }
    end

    context "when a non-https URL is passed" do
      let(:url) { URI.parse("data:,Hello%2C%20World%21") }

      it { is_expected.to be_nil }
    end

    context "when asking for two different URLs" do
      let(:second_url) { URI.parse("https://other.example.com") }

      it "calls the provider query twice" do
        subject
        handler.html_for(second_url)

        expect(query).to have_received(:call).twice
        expect(query).to have_received(:call).with(input_data: having_attributes(url: url.to_s), auth_strategy:)
        expect(query).to have_received(:call).with(input_data: having_attributes(url: second_url.to_s), auth_strategy:)
      end
    end

    context "when asking for the same URL twice" do
      it "calls the provider query once" do
        subject
        handler.html_for(url)

        expect(query).to have_received(:call).once
      end
    end
  end
end
