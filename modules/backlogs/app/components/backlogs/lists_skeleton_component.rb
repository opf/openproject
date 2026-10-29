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

module Backlogs
  class ListsSkeletonComponent < ApplicationComponent
    private

    def with_placeholder_content(blankslate, icon:)
      blankslate.with_visual_icon(icon:, classes: "v-hidden")
      blankslate.with_heading(tag: :h4) { placeholder_line("40%") }
      blankslate.with_description { safe_join([placeholder_line("80%"), placeholder_line("50%")]) }
    end

    def placeholder_line(width)
      render(Primer::Alpha::SkeletonBox.new(width:, height: "1lh", mx: :auto))
    end
  end
end
