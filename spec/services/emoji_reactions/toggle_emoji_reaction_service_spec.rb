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

RSpec.describe EmojiReactions::ToggleEmojiReactionService do
  shared_let(:user) { create(:user, admin: true) }
  shared_let(:work_package) { create(:work_package) }
  shared_let(:reactable) do
    create(:work_package_journal, user: user, notes: "A Note", journable: work_package, version: 2)
  end

  let(:reaction) { "thumbs_up" }

  before do
    allow(EmojiReactions::CreateService).to receive(:new).and_call_original
    allow(EmojiReactions::DeleteService).to receive(:new).and_call_original
  end

  describe ".call" do
    it "toggles the reaction" do
      aggregate_failures "creates if not exists" do
        expect do
          described_class.call(user:, reactable:, reaction:)
        end.to change(EmojiReaction, :count).by(1)

        expect(EmojiReactions::CreateService).to have_received(:new).with(user:)
      end

      emoji_reaction = EmojiReaction.last

      aggregate_failures "deletes if exists" do
        expect do
          described_class.call(user:, reactable:, reaction:)
        end.to change(EmojiReaction, :count).by(-1)

        expect(EmojiReactions::DeleteService).to have_received(:new).with(user:, model: emoji_reaction)
      end
    end
  end
end
