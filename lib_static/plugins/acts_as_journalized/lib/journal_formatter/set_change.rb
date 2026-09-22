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

module JournalFormatter
  # Renders the added/removed difference between two id sets. Including
  # formatters resolve ids to names in the block, keeping their own
  # placeholders for deleted or hidden records.
  module SetChange
    private

    def set_change?(old_ids, new_ids)
      old_ids.any? && new_ids.any? && !(old_ids.one? && new_ids.one?)
    end

    def render_set_change(label_text, old_ids, new_ids, options, &)
      label_text = content_tag(:strong, label_text) if options[:html]
      added = set_change_names(new_ids - old_ids, options, &)
      removed = set_change_names(old_ids - new_ids, options, &)

      lines = []
      lines << I18n.t(:text_journal_set_added, label: label_text, value: added) if added.present?
      lines << I18n.t(:text_journal_set_removed, label: label_text, old: removed) if removed.present?
      lines.join(options[:html] ? "<br/>" : "\n")
    end

    def set_change_names(ids, options)
      names = yield(ids)
      return names if names.blank? || !options[:html]

      content_tag(:i, h(names))
    end

    def ids_from(value)
      value.to_s.split(",").map(&:to_i)
    end
  end
end
