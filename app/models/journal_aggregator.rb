#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class JournalAggregator
  MAX_TEMPORAL_DISTANCE = 300 # Maximum time between two journals in seconds

  class << self
    def merge_journals(journals_array)
      aggregated_journals = []
      journal_queue = journals_array.dup.sort_by &:created_at

      while current_journal = journal_queue.shift
        journal_queue.dup.each do |merge_candidate|
          if are_compatible?(current_journal, merge_candidate)
            if are_mergeable?(current_journal, merge_candidate)
              current_journal = merge(current_journal, merge_candidate)
              journal_queue.delete(merge_candidate)
            else
              aggregated_journals << current_journal
              next
            end
          end
        end

        aggregated_journals << current_journal
      end

      aggregated_journals
    end

    private

    def merge(journal_a, journal_b)
      if !are_mergeable?(journal_a, journal_b)
        raise ArgumentError.new('The given journals cannot be merged.')
      end

      AggregatedJournal.new(journal_a, journal_b)
    end

    def are_compatible?(journal_a, journal_b)
      journal_a.journable_id == journal_b.journable_id
    end

    def are_mergeable?(journal_a, journal_b)
      if journal_a.equal?(journal_b)
        return true
      end

      if journal_a.user_id != journal_b.user_id
        return false
      end

      # The journals need to be consecutive
      if (journal_a.id - journal_b.id).abs != 1
        return false
      end

      # Never merge comments
      if journal_a.notes.present? && journal_b.notes.present?
        return false
      end

      if (journal_a.created_at - journal_b.created_at).abs > MAX_TEMPORAL_DISTANCE
        return false
      end

      true
    end
  end
end
