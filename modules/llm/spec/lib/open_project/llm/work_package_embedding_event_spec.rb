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
# along with this program; if not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe "Subscription to the aggregated journal event", with_settings: { journal_aggregation_time_minutes: 0 } do # rubocop:disable RSpec/DescribeClass
  let(:work_package) { create(:work_package, subject: "Fix login bug", description: "Users cannot log in.") }
  let(:semantic_index) { create(:semantic_index, state: "ready") }

  before do
    allow(Llm::WorkPackages::SemanticSearch).to receive_messages(available?: true, active_semantic_index: semantic_index)
  end

  it "enqueues an embedding for the journal's work package" do
    work_package.update!(subject: "Fix logout bug")
    journal = work_package.journals.reload.last

    OpenProject::Notifications.send(OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
                                    journal:,
                                    send_mail: false)

    expect(Llm::EmbedWorkPackagesJob).to have_been_enqueued.once.with(semantic_index.id, [work_package.id])
  end
end
