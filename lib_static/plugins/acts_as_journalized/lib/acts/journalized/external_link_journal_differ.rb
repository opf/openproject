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
  # An added or removed link only reports its url, which is never blank: a nil side stands for the whole link.
  class ExternalLinkJournalDiffer
    def initialize(predecessor, journal)
      @predecessor = predecessor
      @journal = journal
    end

    def changes
      attribute_changes.reject { |key, _| part_of_added_or_removed_link?(key) }
    end

    private

    def attribute_changes
      Differ::Association
        .new(@predecessor, @journal, association: :external_link_journals, id_attribute: :external_link_id)
        .multiple_attributes_changes(Journal::ExternalLinkJournal.journaled_attributes, key_prefix: "external_links")
    end

    def part_of_added_or_removed_link?(key)
      id, attribute = key.delete_prefix("external_links_").split("_", 2)

      attribute != "url" && added_or_removed_link_ids.include?(id.to_i)
    end

    def added_or_removed_link_ids
      @added_or_removed_link_ids ||= link_ids(@journal) ^ link_ids(@predecessor)
    end

    def link_ids(journal)
      return Set.new unless journal

      journal.external_link_journals.to_set(&:external_link_id)
    end
  end
end
