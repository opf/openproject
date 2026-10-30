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

RSpec.describe OpenProject::Plugins::FrontendLinking::BundleCheck do
  subject(:check) { described_class.new(stats_file.path, expected:) }

  let(:expected) { %w[budgets openproject-documents] }
  let(:inputs) do
    {
      "src/app/features/plugins/linked/budgets/main.ts" => { "bytesInOutput" => 717 },
      "src/app/features/plugins/linked/openproject-documents/main.ts" => { "bytesInOutput" => 543 }
    }
  end
  let(:stats_file) do
    Tempfile.new(["stats", ".json"]).tap do |file|
      file.write({ outputs: { "main-ABC.js" => { inputs: }, "styles-DEF.css" => {} } }.to_json)
      file.flush
    end
  end

  after { stats_file.close! }

  it "passes when every expected plugin is in the bundle" do
    expect { check.verify! }.not_to raise_error
  end

  context "when an expected plugin is not in the bundle" do
    let(:expected) { %w[budgets openproject-documents openproject-meeting] }

    it "raises with the missing plugin" do
      expect { check.verify! }
        .to raise_error(RuntimeError, "Frontend plugins missing from the compiled bundle: openproject-meeting")
    end
  end

  context "when a plugin entry was tree-shaken out" do
    before { inputs["src/app/features/plugins/linked/openproject-documents/main.ts"]["bytesInOutput"] = 0 }

    it "raises with that plugin" do
      expect { check.verify! }
        .to raise_error(RuntimeError, "Frontend plugins missing from the compiled bundle: openproject-documents")
    end
  end
end
