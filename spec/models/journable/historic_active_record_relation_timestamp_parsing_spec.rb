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

RSpec.describe Journable::HistoricActiveRecordRelation do
  let(:project) { create(:project) }
  let!(:work_package) { create(:work_package, project:) }

  describe "#timestamp_case_when_statements" do
    context "when a Timestamp object wraps a multi-line string" do
      let(:crafted_ts) { Timestamp.new("oneDayAgo@00:00+00:00\n@' extra_content") }
      let(:historic_relation) do
        described_class.new(WorkPackage.all, timestamp: [crafted_ts])
      end

      it "does not allow the extra content to break out of the SQL string literal" do
        sql = historic_relation.send(:timestamp_case_when_statements)
        # The apostrophe in the crafted input must be SQL-escaped (doubled), not left bare.
        # An unescaped @' sequence would close the string literal and allow SQL injection.
        expect(sql).not_to include("@' extra_content")
      end
    end

    context "when a Timestamp object wraps a single-line date-keyword string" do
      let(:valid_ts) { Timestamp.parse("oneDayAgo@00:00+00:00") }
      let(:historic_relation) do
        described_class.new(WorkPackage.all, timestamp: [valid_ts])
      end

      it "generates a WHEN/THEN clause containing the label" do
        sql = historic_relation.send(:timestamp_case_when_statements)
        expect(sql).to match(/WHEN .+ THEN .+oneDayAgo/)
      end
    end
  end
end
