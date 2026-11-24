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

RSpec.describe Import::Jiras::CheckConnectionService, :webmock do
  include_context "with Jira connection stubs"

  subject(:service_result) { described_class.new(jira).call }

  let(:jira) { create(:jira, url:) }

  it "stores every report of the configuration" do
    older_report = described_class.new(jira).call.result
    newer_report = described_class.new(jira).call.result

    expect(jira.health_reports.reload).to contain_exactly(older_report, newer_report)
  end

  context "when every check passes" do
    it { expect(service_result).to be_success }
  end

  context "when a check fails" do
    let(:administrator) { false }

    it "fails with the stored report" do
      expect(service_result).to be_failure
      expect(service_result.result).to be_persisted
    end
  end
end
