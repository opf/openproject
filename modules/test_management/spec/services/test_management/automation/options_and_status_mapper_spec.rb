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

RSpec.describe "TestManagement::Automation options and status mapping" do # rubocop:disable RSpec/DescribeClass
  let(:mapper_class) { TestManagement::Automation::StatusMapper }
  let(:options_class) { TestManagement::Automation::Options }

  describe TestManagement::Automation::StatusMapper do
    it "maps the usual statuses of Playwright and JUnit" do
      mapper = mapper_class.new

      expect(%w[passed expected failed timedOut interrupted skipped flaky].map { |s| mapper.call(s) })
        .to eq(%w[passed passed failed failed blocked skipped passed])
    end

    it "applies skippedAs, flakyAs and the statusMap" do
      mapper = mapper_class.new(skipped_as: "ignore", flaky_as: "retest", status_map: { "broken" => "blocked" })

      expect(mapper.call("skipped")).to be_nil
      expect(mapper.call("flaky")).to eq("retest")
      expect(mapper.call("Broken")).to eq("blocked")
      expect { mapper.call("exploded") }.to raise_error(KeyError)
    end
  end

  describe TestManagement::Automation::Options do
    it "accepts camelCase and snake_case keys and keeps only known CI keys" do
      options = options_class.new("closeRun" => "true", "case_matcher" => "reference",
                                  "ci" => { "runUrl" => "https://ci.example.com/1", "token" => "secret" })

      expect(options).to be_close_run
      expect(options.case_matcher).to eq("reference")
      expect(options.ci).to eq("runUrl" => "https://ci.example.com/1")
    end

    it "has defaults" do
      options = options_class.new

      expect(options.format).to eq("auto")
      expect(options.skipped_as).to eq("skipped")
      expect(options).to be_update_references
      expect(options).not_to be_close_run
    end

    it "rejects invalid values with :unprocessable" do
      expect { options_class.new("caseMatcher" => "magic") }
        .to raise_error(TestManagement::Automation::Error) { |e| expect(e.code).to eq(:unprocessable) }
      expect { options_class.new("statusMap" => { "x" => "nope" }) }
        .to raise_error(TestManagement::Automation::Error) { |e| expect(e.code).to eq(:unprocessable) }
    end
  end
end
