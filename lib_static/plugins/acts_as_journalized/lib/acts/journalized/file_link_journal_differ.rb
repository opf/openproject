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

module Acts::Journalized
  module FileLinkJournalDiffer
    class << self
      def get_changes_to_file_links(predecessor, storable_journals)
        if predecessor.nil?
          storable_journals.each_with_object({}) do |journal, hash|
            change_key = "file_links_#{journal.file_link_id}"
            new_values = { link_name: journal.link_name, storage_name: journal.storage_name }
            hash[change_key] = [nil, new_values]
          end
        else
          current_storables = storable_journals.map(&:attributes)
          previous_storables = predecessor.storable_journals.map(&:attributes)

          changes_on_file_links(previous_storables, current_storables)
        end
      end

      def changes_on_file_links(previous, current)
        ids = all_file_link_ids(previous, current)

        cleanup_changes(
          pair_changes(ids, previous, current)
        ).transform_keys! { |key| "file_links_#{key}" }
      end

      def all_file_link_ids(previous, current)
        current.pluck("file_link_id") | previous.pluck("file_link_id")
      end

      def cleanup_changes(changes) = changes.reject { |_, (first, last)| first == last }

      def pair_changes(ids, previous, current)
        ids.index_with do |id|
          [select_journals(previous.select { |attributes| attributes["file_link_id"] == id }),
           select_journals(current.select { |attributes| attributes["file_link_id"] == id })]
        end
      end

      def select_journals(journals)
        return if journals.empty?

        journals.sort.map { |hash| hash.slice("link_name", "storage_name") }.last
      end
    end
  end
end
