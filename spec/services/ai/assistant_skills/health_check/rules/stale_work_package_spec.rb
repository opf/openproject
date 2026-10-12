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
require_relative "../shared_context"

RSpec.describe AI::AssistantSkills::HealthCheck::Rules::StaleWorkPackage do
  include_context "with a health check context"

  subject(:findings) { described_class.call(context) }

  context "when nothing changed for 90 days" do
    before do
      work_package.journals.update_all(created_at: 90.days.ago)
      work_package.update_column(:updated_at, 90.days.ago)
    end

    it "reports a low finding" do
      expect(findings.size).to eq(1)
      expect(findings.first.text).to include("90 days")
    end

    context "and the work package is closed" do
      let(:work_package_status) { closed_status }

      it { is_expected.to be_empty }
    end
  end

  context "when it changed recently" do
    it { is_expected.to be_empty }
  end
end
