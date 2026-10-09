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

# It's actually a bit random to test if the URL was actuall copied to the
# clipboard, because copying to clipboard may not work with headless browsers,
# probably due to missing clipboard permissions of the headless browser.
#
# Tried following without success
# https://copyprogramming.com/howto/emulating-a-clipboard-copy-paste-with-selinum-capybara
#
# Approach here is to account for that and expect either the copy successful
# message or the fallback message when copying is not possible.
#
# This is not 100% deterministic, but it's the best we can do for now.

RSpec::Matchers.define :have_message_copied_to_clipboard do |copied_content, successful_copy_message: nil|
  successful_copy_message ||= "Successfully copied to clipboard!"

  match do |page|
    # The clipboard service can either succeed or fail to copy to clipboard.
    #   On success: shows "Successfully copied to clipboard!"
    #   On failure: shows "Your browser doesn't support copying to clipboard. Please copy it manually: <copied_content>"
    # See frontend/src/app/shared/components/copy-to-clipboard/copy-to-clipboard.service.ts for more details.
    pattern = Regexp.union(
      /#{Regexp.escape(successful_copy_message)}/,
      /Your browser doesn't support copying to clipboard\. Please copy it manually: .*#{Regexp.escape(copied_content)}/
    )
    page.has_content?(pattern)
  end

  failure_message do
    "expected page to show either copy success message '#{successful_copy_message}' or the clipboard content '#{copied_content}'"
  end

  failure_message_when_negated do
    "expected page not to show clipboard-related messages for '#{content}' nor copy success message '#{successful_copy_message}'"
  end
end
