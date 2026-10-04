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

module TableHelpers
  class Table
    def initialize(work_packages_by_identifier, relations)
      @work_packages_by_identifier = work_packages_by_identifier
      @relations = relations
    end

    def work_package(name)
      name = normalize_name(name)
      @work_packages_by_identifier[name]
    end

    def work_packages
      @work_packages_by_identifier.values
    end

    # Finds a relation by its predecessor and/or successor.
    #
    # Example:
    #
    #   relation(successor: "succ")
    #
    # will return the first created follows/precedes relation having the successor with subject "succ".
    #
    # @param predecessor [String, nil] the predecessor's subject name
    # @param successor [String, nil] the successor's subjectname
    # @return [Relation, nil] the relation or nil if no relation matches
    def relation(predecessor: nil, successor: nil)
      @relations.find do |relation|
        relation.follows? \
          && (predecessor.nil? || relation.predecessor.subject == subject_of(predecessor)) \
          && (successor.nil? || relation.successor.subject == subject_of(successor))
      end
    end

    def relations
      @relations
    end

    def monday = Date.current.next_occurring(:monday)
    def tuesday = monday + 1.day
    def wednesday = monday + 2.days
    def thursday = monday + 3.days
    def friday = monday + 4.days
    def saturday = monday + 5.days
    def sunday = monday + 6.days
    def next_monday = monday + 7.days
    def next_tuesday = monday + 8.days
    def next_wednesday = monday + 9.days
    def next_thursday = monday + 10.days
    def next_friday = monday + 11.days
    def next_saturday = monday + 12.days
    def next_sunday = monday + 13.days

    private

    def subject_of(object)
      case object
      when nil
        nil
      when String
        object
      when WorkPackage
        object.subject
      else
        raise "Cannot find subject for #{object.inspect}"
      end
    end

    def normalize_name(name)
      symbolic_name = name.to_sym
      return symbolic_name if @work_packages_by_identifier.has_key?(symbolic_name)

      spell_checker = DidYouMean::SpellChecker.new(dictionary: @work_packages_by_identifier.keys.map(&:to_s))
      suggestions = spell_checker.correct(name).map(&:inspect).join(" ")
      did_you_mean = " Did you mean #{suggestions} instead?" if suggestions.present?
      raise "No work package with name #{name.inspect} in _table.#{did_you_mean}"
    end
  end
end
