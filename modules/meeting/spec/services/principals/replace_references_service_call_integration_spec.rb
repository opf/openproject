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
require_module_spec_helper
require Rails.root.join("spec/services/principals/replace_references_context")

RSpec.describe Principals::ReplaceReferencesService, "#call", type: :model do
  subject(:service_call) { instance.call(from: principal, to: to_principal) }

  shared_let(:other_user) { create(:user, firstname: "other user") }
  shared_let(:principal) { create(:user, firstname: "old principal") }
  shared_let(:to_principal) { create(:user, firstname: "new principal") }

  let(:instance) do
    described_class.new
  end

  context "with MeetingAgendaItem" do
    it_behaves_like "rewritten record",
                    :meeting_agenda_item,
                    :author_id

    it_behaves_like "rewritten record",
                    :meeting_agenda_item,
                    :presenter_id
  end

  context "with Journal::MeetingAgendaItemJournal" do
    it_behaves_like "rewritten record",
                    :journal_meeting_agenda_item_journal,
                    :author_id
  end
end
