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
require "tmpdir"
require "open_project/api_doc_coverage/ledger"

RSpec.describe OpenProject::ApiDocCoverage::Ledger do
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, ".coverage-wps.yml") }

  after { FileUtils.remove_entry(dir) }

  it "returns nil for an unknown module and persists recorded ids" do
    ledger = described_class.new(path)
    expect(ledger.id_for("widgets")).to be_nil
    ledger.record("widgets", "12345")
    expect(described_class.new(path).id_for("widgets")).to eq("12345")
  end
end
