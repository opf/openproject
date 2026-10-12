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

RSpec.describe AI::AssistantSkills::HealthCheck::Rules::OpenDuplicateOfClosed do
  include_context "with a health check context"

  subject(:findings) { described_class.call(context) }

  let(:original) { create(:work_package, project:, status: closed_status) }

  context "when it duplicates a closed work package" do
    before { create(:relation, from: work_package, to: original, relation_type: Relation::TYPE_DUPLICATES) }

    it "reports a medium finding" do
      expect(findings.size).to eq(1)
      expect(findings.first.evidence.first["work_package_id"]).to eq(original.id)
    end
  end

  context "when a closed work package duplicates it" do
    before { create(:relation, from: original, to: work_package, relation_type: Relation::TYPE_DUPLICATES) }

    it { is_expected.to be_empty }
  end
end
