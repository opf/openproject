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

RSpec.describe ReportingHelper do
  describe "#field_representation_map" do
    context "for a custom field" do
      context "for which a custom option exists (e.g. a list field)" do
        let(:custom_field) do
          create(
            :list_wp_custom_field,
            name: "Ingredients",
            possible_values: ["ham"]
          )
        end

        it "returns the option value" do
          option = custom_field.possible_values.first

          expect(field_representation_map("custom_field#{custom_field.id}", option.id))
            .to eql "ham"
        end

        it "returns not found for an outdated value value" do
          expect(field_representation_map("custom_field#{custom_field.id}", "1234123"))
            .to eql "1234123 not found"
        end
      end

      context "for which no custom option exists (e.g. a float field)" do
        let(:custom_field) do
          create(
            :float_wp_custom_field,
            name: "Estimate"
          )
        end

        it "returns the option value" do
          expect(field_representation_map("custom_field#{custom_field.id}", 3.0))
            .to eq "3.0"
        end
      end
    end

    context "for which no custom option exists" do
      it "returns the not found value" do
        expect(field_representation_map("custom_field12345", "345"))
          .to eql "345 not found"
      end
    end
  end
end
