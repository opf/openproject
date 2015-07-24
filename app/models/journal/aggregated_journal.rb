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

class AggregatedJournal
  def initialize(*journals)
    journals.combination(2).each do |journal_a, journal_b|
      unless JournalAggregator.are_mergeable?(journal_a, journal_b)
        raise ArgumentError.new('The given journals have to be mergeable.')
      end
    end
    @journals = journals
  end

  def journaled_attributes
    ordered_journals = @journals.map(&:attributes).sort_by { |journal| journal[:id] }

    combined_journals = {}
    ordered_journals.each do |journal|
      combined_journals = combined_journals.merge(journal)
    end

    combined_journals['notes'] =
      @journals.map(&:attributes).map { |hash| hash['notes'] }.compact.first
    combined_journals.symbolize_keys
  end
end
