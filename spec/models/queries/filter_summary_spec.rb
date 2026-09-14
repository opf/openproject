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

RSpec.describe Queries::FilterSummary do
  shared_let(:job_title) do
    create(:user_custom_field, :list, name: "Job title", possible_values: %w[Developer Designer])
  end
  shared_let(:language) do
    create(:user_custom_field, :list, name: "Spoken language", multi_value: true,
                                      possible_values: %w[German English French])
  end

  def query_with(&)
    UserQuery.new.tap(&)
  end

  describe "#phrases / #to_s" do
    it "resolves a custom-field list filter's option ids to their labels" do
      option = job_title.custom_options.find_by(value: "Developer")
      query = query_with { |q| q.where(job_title.column_name, "=", [option.id.to_s]) }

      summary = described_class.new(query.filters)

      # "is (OR)" is the label OpenProject uses for the list-equals operator.
      expect(summary.phrases).to eq(["Job title is (OR) Developer"])
      expect(summary.to_s).to eq("Job title is (OR) Developer")
    end

    it "joins multiple values and multiple filters" do
      developer = job_title.custom_options.find_by(value: "Developer")
      langs = language.custom_options.where(value: %w[German English])
      query = query_with do |q|
        q.where(job_title.column_name, "=", [developer.id.to_s])
        q.where(language.column_name, "=", langs.map { |o| o.id.to_s })
      end

      summary = described_class.new(query.filters)

      expect(summary.phrases).to eq(["Job title is (OR) Developer", "Spoken language is (OR) German, English"])
      expect(summary.to_s).to eq("Job title is (OR) Developer · Spoken language is (OR) German, English")
      expect(summary.to_s(separator: "; "))
        .to eq("Job title is (OR) Developer; Spoken language is (OR) German, English")
    end

    it "is empty for no filters" do
      expect(described_class.new([])).to be_empty
      expect(described_class.new(nil).phrases).to eq([])
    end
  end
end
