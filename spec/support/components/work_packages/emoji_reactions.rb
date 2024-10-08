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

module Components
  module WorkPackages
    class EmojiReactions < Activities
      def can_add_emoji_reaction_for_journal(journal, emoji, expected_emoji_count: 1)
        within_journal_entry(journal) do
          click_on "Add reaction"
          click_on emoji

          page.within_test_selector("emoji-reactions") do
            expect(page).to have_text("#{emoji} #{expected_emoji_count}")
          end
        end
      end

      def can_remove_emoji_reaction_for_journal(journal, emoji)
        within_journal_entry(journal) do
          page.within_test_selector("emoji-reactions") do
            click_on emoji
            expect(page).to have_no_text(emoji)
          end
        end
      end

      def expect_add_reactions_button
        expect(page).to have_test_selector("add-reactions-button")
      end

      def expect_no_add_reactions_button
        expect(page).not_to have_test_selector("add-reactions-button")
      end
    end
  end
end
