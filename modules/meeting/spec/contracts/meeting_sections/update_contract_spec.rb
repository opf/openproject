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

RSpec.describe MeetingSections::UpdateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:section) { create(:meeting_section, meeting:) }
  let(:contract) { described_class.new(section, user) }

  context "with permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => [:manage_agendas] })
    end

    it_behaves_like "contract is valid"

    context "when :meeting is not editable" do
      before do
        meeting.update_column(:state, :closed)
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_agenda_item_not_editable_anymore)
    end

    context "when the section is the backlog" do
      let(:section) { meeting.backlog }

      it_behaves_like "contract is invalid", base: :error_readonly
    end
  end

  context "without permission" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "with permission in another project" do
    let(:user) do
      create(:user, member_with_permissions: { other_project => %i[view_meetings manage_agendas] })
    end

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "when the meeting is changed" do
    let(:user) do
      create(:user, member_with_permissions: { project => [:manage_agendas] })
    end
    let(:other_meeting) { create(:meeting, project: other_project) }

    before do
      section.meeting = other_meeting
    end

    it_behaves_like "contract is invalid", meeting_id: :error_readonly
  end

  include_examples "contract reuses the model errors" do
    let(:user) { build_stubbed(:user) }
  end
end
