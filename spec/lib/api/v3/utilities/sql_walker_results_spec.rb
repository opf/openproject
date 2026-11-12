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

RSpec.describe API::V3::Utilities::SqlWalkerResults do
  describe "#select?" do
    subject { described_class.new(WorkPackage.none, url_query:).select?(*path, attribute) }

    let(:url_query) { { select: query_selects } }
    let(:query_selects) { { "foo" => {}, "prefix" => { "bar" => {} } } }

    let(:path) { [] }
    let(:attribute) { "foo" }

    it { is_expected.to be_truthy }

    context "when asking for a non-mentioned attribute" do
      let(:attribute) { "bar" }

      it { is_expected.to be_falsey }
    end

    context "when asking for an attribute with members" do
      let(:attribute) { "prefix" }

      it { is_expected.to be_falsey }
    end

    context "when the query selects *" do
      let(:query_selects) { { "*" => {} } }

      it { is_expected.to be_truthy }

      context "and asking for a nested attribute" do
        let(:path) { ["prefix"] }

        it { is_expected.to be_falsey }
      end
    end

    context "when asking for a nested attribute" do
      let(:path) { ["prefix"] }
      let(:attribute) { "bar" }

      it { is_expected.to be_truthy }

      context "and the attribute is not mentioned" do
        let(:attribute) { "foo" }

        it { is_expected.to be_falsey }
      end

      context "when the query selects prefix/*" do
        let(:query_selects) { { "prefix" => { "*" => {} } } }

        it { is_expected.to be_truthy }

        context "and asking for a non-nested attribute" do
          let(:path) { [] }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
