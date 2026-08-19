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

RSpec.describe CostReports::LegacyFilters do
  subject(:filters_param) do
    described_class.new(operators: { "Subject" => "~" }, values: { "Subject" => values }).to_params[:filters]
  end

  # The values reach the report again through the parser, so what matters is that
  # they survive the round trip rather than the exact escaping on the way out.
  def round_tripped
    Queries::ParamsParser.parse({ filters: "#{filters_param} & project_id = \"5\"" }.with_indifferent_access)[:filters]
  end

  describe "#to_params" do
    context "with a plain value" do
      let(:values) { ["some subject"] }

      it { is_expected.to eq('subject ~ "some subject"') }
    end

    context "with a value containing a double quote" do
      let(:values) { ['say "hi"'] }

      it { is_expected.to eq('subject ~ "say \\"hi\\""') }

      it "round trips" do
        expect(round_tripped.first).to eq({ attribute: "subject", operator: "~", values: ['say "hi"'] })
      end
    end

    context "with a value containing a backslash" do
      let(:values) { ['C:\some\path'] }

      it { is_expected.to eq('subject ~ "C:\\\\some\\\\path"') }

      it "round trips" do
        expect(round_tripped.first).to eq({ attribute: "subject", operator: "~", values: ['C:\some\path'] })
      end
    end

    context "with a value ending on a backslash" do
      let(:values) { ["trailing\\"] }

      it "escapes it so that it does not swallow the filters that follow" do
        expect(round_tripped)
          .to eq([{ attribute: "subject", operator: "~", values: ["trailing\\"] },
                  { attribute: "project_id", operator: "=", values: ["5"] }])
      end
    end

    context "with multiple values needing escaping" do
      let(:values) { ['a"b', "c\\"] }

      it { is_expected.to eq('subject ~ ["a\\"b","c\\\\"]') }

      it "round trips" do
        expect(round_tripped.first).to eq({ attribute: "subject", operator: "~", values: ['a"b', "c\\"] })
      end
    end
  end
end
