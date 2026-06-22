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
require_module_spec_helper

RSpec.describe Wikis::PageLinkViewModel do
  let(:provider) { build_stubbed(:internal_wiki_provider) }
  let(:page_info) do
    Wikis::Adapters::Results::PageInfo.new(
      identifier: "42",
      title: "Test page",
      provider:,
      href: "https://wiki.example.com/test"
    )
  end
  let(:failure_result) { Failure(Wikis::Adapters::Results::Error.new(source: nil, code: :not_found)) }

  describe ".from_reference" do
    subject(:view_model) { described_class.from_reference(result) }

    context "when the result is a link" do
      let(:result) { Success(Wikis::Adapters::Results::PageReference.new(page_info:, source: :link)) }

      it "extracts the page_info_result from the reference" do
        expect(view_model.page_info_result).to be_success
        expect(view_model.page_info_result.value!).to eq(page_info)
      end

      it "carries the link source" do
        expect(view_model.source).to eq(:link)
      end
    end

    context "when the result is a mention" do
      let(:result) { Success(Wikis::Adapters::Results::PageReference.new(page_info:, source: :mention)) }

      it "extracts the page_info_result from the reference" do
        expect(view_model.page_info_result).to be_success
        expect(view_model.page_info_result.value!).to eq(page_info)
      end

      it "carries the mention source" do
        expect(view_model.source).to eq(:mention)
      end
    end

    context "when the result is a failure" do
      let(:result) { failure_result }

      it "passes the failure through as page_info_result" do
        expect(view_model.page_info_result).to be_failure
      end

      it "carries no source" do
        expect(view_model.source).to be_nil
      end
    end
  end

  describe ".from_inline" do
    subject(:view_model) { described_class.from_inline(result) }

    context "when the result is a success" do
      let(:result) { Success(page_info) }

      it "passes the page_info_result through unchanged" do
        expect(view_model.page_info_result).to be_success
        expect(view_model.page_info_result.value!).to eq(page_info)
      end

      it "carries no source" do
        expect(view_model.source).to be_nil
      end
    end

    context "when the result is a failure" do
      let(:result) { failure_result }

      it "passes the failure through as page_info_result" do
        expect(view_model.page_info_result).to be_failure
      end

      it "carries no source" do
        expect(view_model.source).to be_nil
      end
    end
  end
end
