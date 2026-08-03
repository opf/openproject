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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::Bim::BcfXml::Aggregations do
  subject(:aggregations) { described_class.new(listings, project) }

  shared_let(:project) { create(:project) }
  shared_let(:root_type) { create(:type, name: "Issue") }

  let(:listings) { [{ type: topic_types, status: [], people: [] }] }

  describe "#unknown_types" do
    context "with a topic type matching an existing type" do
      let(:topic_types) { ["Issue"] }

      it "is empty" do
        expect(aggregations.unknown_types).to be_empty
      end
    end

    context "with a topic type no type is named after" do
      let(:topic_types) { ["Clash"] }

      it "reports it as unknown" do
        expect(aggregations.unknown_types).to eq(["Clash"])
      end
    end

    # A variant carries the name of its root, so matching against its own label would
    # accept a name no work package ever shows.
    context "with a variant in the family", with_flag: { type_variants: true } do
      shared_let(:variant) { create(:type, name: "Clash detection", parent: root_type) }

      context "with a topic type named after the root" do
        let(:topic_types) { ["Issue"] }

        it "is empty" do
          expect(aggregations.unknown_types).to be_empty
        end
      end

      context "with a topic type named after the variant itself" do
        let(:topic_types) { ["Clash detection"] }

        it "reports it as unknown" do
          expect(aggregations.unknown_types).to eq(["Clash detection"])
        end
      end
    end
  end
end
