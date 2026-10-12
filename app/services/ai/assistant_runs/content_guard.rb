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

module AI
  module AssistantRuns
    # A proposed description must keep what the model cannot recreate: attachment
    # references, mentions and macros. Returns the ones the proposal drops.
    module ContentGuard
      PATTERNS = [
        %r{/api/v3/attachments/\d+(?:/content)?},
        /<mention\b[^>]*>/,
        /<macro\b[^>]*>/,
        /\{\{[^}]+\}\}/
      ].freeze

      module_function

      def lost_references(old_text, new_text)
        old_text = old_text.to_s
        new_text = new_text.to_s

        PATTERNS.flat_map { |pattern| old_text.scan(pattern) }
                .uniq
                .reject { |reference| new_text.include?(reference) }
      end
    end
  end
end
