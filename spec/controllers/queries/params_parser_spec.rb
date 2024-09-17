# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Queries::ParamsParser, type: :model do
  let(:params) do
    {}
  end

  subject { described_class.parse(params.with_indifferent_access) }

  describe ".parse" do
    context "without any params" do
      it "returns an empty array" do
        expect(subject)
          .to be_empty
      end
    end

    context "with a single filter with a single value" do
      let(:params) do
        {
          filters: "active = t"
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: ["t"] })
      end
    end

    context "with a single filter with multiple values having single quotes" do
      let(:params) do
        {
          filters: "active = ['t', 'f']"
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: %w[t f] })
      end
    end

    context "with a single filter with multiple values having double quotes" do
      let(:params) do
        {
          filters: "active = [\"t\", \"f\"]"
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: %w[t f] })
      end
    end

    context "with a single filter with a single value with , and &" do
      let(:params) do
        {
          filters: "active = something, or another thing & something else"
        }
      end

      it "returns the parsed filter" do
        # This returns invalid filters but they will then be marked as invalid
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: ["something, or another thing "] },
                              { attribute: "something", operator: "else", values: [""] })
      end
    end

    context 'with a single filter with a single value with " (escaped)' do
      let(:params) do
        {
          filters: 'active = "something, or another thing \" something else"'
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: ["something, or another thing \" something else"] })
      end
    end

    context "with a single filter with a single value with ' (escaped)" do
      let(:params) do
        {
          filters: "active = 'something, or another thing \\' something else'"
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: ["something, or another thing ' something else"] })
      end
    end

    context "with a single filter with no value" do
      let(:params) do
        {
          filters: "cf_512 !* "
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "cf_512", operator: "!*", values: [""] })
      end
    end

    context "with multiple filters with the first having no value" do
      let(:params) do
        {
          filters: "active !* & id = \"1\""
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "!*", values: [] },
                              { attribute: "id", operator: "=", values: ["1"] })
      end
    end

    context "with multiple filters with ampersand as a filter value" do
      let(:params) do
        {
          filters: "active = \"t\" & name_and_identifier ~ \"abc & def\""
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: ["t"] },
                              { attribute: "name_and_identifier", operator: "~", values: ["abc & def"] })
      end
    end

    context "with a corrupt filter only having a key" do
      let(:params) do
        {
          filters: "active"
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "", values: [""] })
      end
    end

    context "with a corrupt filter having opening braces but no closing ones" do
      let(:params) do
        {
          filters: "active = [\"t\", \"f\""
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: %w[t f] })
      end
    end

    context "with a corrupt filter having opening double quotes but no closing ones" do
      let(:params) do
        {
          filters: 'active = "t'
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: %w[t] })
      end
    end

    context "with a corrupt filter having opening single quotes but no closing ones" do
      let(:params) do
        {
          filters: "active = 't"
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: %w[t] })
      end
    end

    context "with an old (APIv3) style filter" do
      let(:params) do
        {

          filters: JSON.dump([{ active: { operator: "=", values: ["f"] } },
                              { cf_32: { operator: "=", values: ["63"] } }, # rubocop:disable Naming/VariableNumber
                              { cf_34: { operator: "=", values: ["2006"] } }]) # rubocop:disable Naming/VariableNumber
        }
      end

      it "returns the parsed filter" do
        expect(subject[:filters])
          .to contain_exactly({ attribute: "active", operator: "=", values: %w[f] },
                              { attribute: "cf_32", operator: "=", values: %w[63] },
                              { attribute: "cf_34", operator: "=", values: %w[2006] })
      end
    end

    context "with sortBy with a single value" do
      let(:params) do
        {
          sortBy: JSON.dump([%w[name asc]])
        }
      end

      it "returns the parsed filter" do
        expect(subject[:orders])
          .to eql [{ attribute: "name", direction: "asc" }]
      end
    end

    context "with sortBy with a multiple value" do
      let(:params) do
        {
          sortBy: JSON.dump([%w[name asc], %w[created_at desc]])
        }
      end

      it "returns the parsed filter" do
        expect(subject[:orders])
          .to eql [{ attribute: "name", direction: "asc" }, { attribute: "created_at", direction: "desc" }]
      end
    end

    context "with an invalid sortBy" do
      let(:params) do
        {
          sortBy: "[sjfkdsjfkd}"
        }
      end

      it "returns an invalid sort order" do
        expect(subject[:orders])
          .to eql [{ attribute: "invalid", direction: "asc" }]
      end
    end

    context "with multiple columns" do
      let(:params) do
        {
          columns: "name cf_1 project_status"
        }
      end

      it "returns an invalid sort order" do
        expect(subject[:selects])
          .to eql %w[name cf_1 project_status]
      end
    end
  end
end
