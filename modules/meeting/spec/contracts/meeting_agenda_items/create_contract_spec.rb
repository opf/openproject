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

RSpec.describe MeetingAgendaItems::CreateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }
  let(:meeting) { create(:structured_meeting, project:) }
  let(:item) { build(:meeting_agenda_item, meeting:) }
  let(:contract) { described_class.new(item, user) }

  context "with permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] })
    end

    it_behaves_like "contract is valid"

    context "when :meeting is not editable" do
      before do
        meeting.update_column(:state, :closed)
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_agenda_item_not_editable_anymore)
    end

    context "when :meeting is not present anymore" do
      before do
        meeting.destroy
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when an item_type is provided" do
      before do
        allow(item).to receive(:changed).and_return(["item_type"])
      end

      it_behaves_like "contract is valid"
    end
  end

  context "without permission" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :does_not_exist
  end

  include_examples "contract reuses the model errors" do
    let(:user) { build_stubbed(:user) }
  end
end
