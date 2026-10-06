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
require "contracts/shared/model_contract_shared_context"

RSpec.describe MeetingAgendaItems::VoteContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  let(:meeting) { build_stubbed(:meeting, project:, agenda_sorting_mode: :vote_based) }
  let(:section) { build_stubbed(:meeting_section, meeting:) }
  let(:item) { build_stubbed(:meeting_agenda_item, meeting:, meeting_section: section) }
  let(:reaction) { "thumbs_up" }
  let(:contract_options) { { reaction:, meeting_id: meeting.id } }
  let(:contract) { described_class.new(item, user, options: contract_options) }

  it_behaves_like "contract is valid"

  context "with a downvote" do
    let(:reaction) { "thumbs_down" }

    it_behaves_like "contract is valid"
  end

  context "with a symbol reaction" do
    let(:reaction) { :thumbs_up }

    it_behaves_like "contract is valid"
  end

  %i[draft in_progress].each do |state|
    context "when the meeting is #{state}" do
      let(:meeting) { build_stubbed(:meeting, project:, agenda_sorting_mode: :vote_based, state:) }

      it_behaves_like "contract is valid"
    end
  end

  ["heart", "", nil].each do |reaction|
    context "with reaction #{reaction.inspect}" do
      let(:reaction) { reaction }

      it_behaves_like "contract is invalid", base: I18n.t("meeting.agenda_sorting.invalid_reaction")
    end
  end

  context "with manual sorting" do
    let(:meeting) { build_stubbed(:meeting, project:) }

    it_behaves_like "contract is invalid", base: :vote_based_sorting_required
  end

  context "without view permission" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized

    context "with manual sorting" do
      let(:meeting) { build_stubbed(:meeting, project:) }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  %i[closed cancelled].each do |state|
    context "when the meeting is #{state}" do
      let(:meeting) { build_stubbed(:meeting, project:, agenda_sorting_mode: :vote_based, state:) }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  context "with a backlog item" do
    let(:section) { build_stubbed(:meeting_section, meeting:, backlog: true) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with a template" do
    let(:meeting) { build_stubbed(:onetime_template, project:, agenda_sorting_mode: :vote_based) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "when the item no longer belongs to the locked meeting" do
    let(:contract_options) { { reaction:, meeting_id: meeting.id + 1 } }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  it "does not validate unrelated agenda item attributes" do
    allow(item).to receive(:valid?).and_return(false)

    expect_contract_valid
    expect(item).not_to have_received(:valid?)
  end

  include_examples "contract reuses the model errors"
end
