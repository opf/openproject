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

RSpec.describe WorkPackage::Exports::Formatters::XLS::Id do
  describe ".apply?" do
    it "applies to the id column of the xls export" do
      expect(described_class.apply?(:id, :xls)).to be true
    end

    it "does not apply to other columns or export formats" do
      expect(described_class.apply?(:subject, :xls)).to be false
      expect(described_class.apply?(:id, :csv)).to be false
      expect(described_class.apply?(:id, :pdf)).to be false
    end
  end

  describe "with classic identifiers", with_settings: { work_packages_identifier: "classic" } do
    let(:work_package) { build_stubbed(:work_package) }

    it "keeps the numeric id a number so that the column stays sortable" do
      expect(described_class.new(:id).format(work_package)).to eq(work_package.id)
    end

    it "formats the column without decimals" do
      expect(described_class.new(:id).format_options).to eq({ number_format: "0" })
    end
  end

  describe "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    let(:work_package) { build_stubbed(:work_package, identifier: "PROJ-42") }

    it "exports the semantic identifier" do
      expect(described_class.new(:id).format(work_package)).to eq("PROJ-42")
    end

    it "leaves the column unformatted, the identifier being text" do
      expect(described_class.new(:id).format_options).to eq({})
    end
  end
end
