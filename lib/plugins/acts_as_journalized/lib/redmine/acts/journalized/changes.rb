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

#-- encoding: UTF-8
# This file included as part of the acts_as_journalized plugin for
# the redMine project management software; You can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either journal 2
# of the License, or (at your option) any later journal.
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
# The original copyright and license conditions are:
# Copyright (c) 2009 Steve Richert
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Redmine::Acts::Journalized
  # Provides the ability to manipulate hashes in the specific format that ActiveRecord gives to
  # dirty attribute changes: string keys and unique, two-element array values.
  module Changes
    def self.included(base) # :nodoc:
      Hash.send(:include, HashMethods)

      base.class_eval do
        include InstanceMethods

        after_save :merge_journal_changes
      end
    end

    # Methods available to journaled ActiveRecord::Base instances in order to manage changes used
    # for journal creation.
    module InstanceMethods
      # Collects an array of changes from a record's journals between the given range and compiles
      # them into one summary hash of changes. The +from+ and +to+ arguments can each be either a
      # version number, a symbol representing an association proxy method, a string representing a
      # journal tag or a journal object itself.
      def changes_between(from, to)
        from_number, to_number = journals.journal_at(from), journals.journal_at(to)
        return {} if from_number == to_number
        chain = journals.between(from_number, to_number).reject(&:initial?)
        return {} if chain.empty?

        backward = from_number > to_number
        backward ? chain.pop : chain.shift unless from_number == 1 || to_number == 1

        chain.inject({}) do |changes, journal|
          changes.append_changes!(backward ? journal.changed_data.reverse_changes : journal.changed_data)
        end
      end

      private

      # Before a new journal is created, the newly-changed attributes are appended onto a hash
      # of previously-changed attributes. Typically the previous changes will be empty, except in
      # the case that a control block is used where journals are to be merged. See
      # VestalVersions::Control for more information.
      def merge_journal_changes
        journal_changes.append_changes!(incremental_journal_changes)
      end

      # Stores the cumulative changes that are eventually used for journal creation.
      def journal_changes
        @journal_changes ||= {}
      end

      # Stores the incremental changes that are appended to the cumulative changes before journal
      # creation. Incremental changes are reset when the record is saved because they represent
      # a subset of the dirty attribute changes, which are reset upon save.
      def incremental_journal_changes
        changed.inject({}) do |h, attr|
          h[attr] = attribute_change(attr) unless !attribute_change(attr).nil? &&
                                                  attribute_change(attr)[0].blank? && attribute_change(attr)[1].blank?
          h
        end.slice(*journaled_columns)
      end

      # Simply resets the cumulative changes after journal creation.
      def reset_journal_changes
        @journal_changes = nil
      end
    end

    # Instance methods included into Hash for dealing with manipulation of hashes in the specific
    # format of ActiveRecord::Base#changes.
    module HashMethods
      # When called on a hash of changes and given a second hash of changes as an argument,
      # +append_changes+ will run the second hash on top of the first, updating the last element
      # of each array value with its own, or creating its own key/value pair for missing keys.
      # Resulting non-unique array values are removed.
      #
      # == Example
      #
      # first = {
      #   "first_name" => ["Steve", "Stephen"],
      #   "age" => [25, 26]
      # }
      # second = {
      #   "first_name" => ["Stephen", "Steve"],
      #   "last_name" => ["Richert", "Jobs"],
      #   "age" => [26, 54]
      # }
      # first.append_changes(second)
      # # => {
      #   "last_name" => ["Richert", "Jobs"],
      #   "age" => [25, 54]
      # }
      def append_changes(changes)
        changes.inject(self) do |new_changes, (attribute, change)|
          new_change = [new_changes.fetch(attribute, change).first, change.last]
          new_changes.merge(attribute => new_change)
        end.reject do |_attribute, change|
          change.first == change.last
        end
      end

      # Destructively appends a given hash of changes onto an existing hash of changes.
      def append_changes!(changes)
        replace(append_changes(changes))
      end

      # Appends the existing hash of changes onto a given hash of changes. Relates to the
      # +append_changes+ method in the same way that Hash#reverse_merge relates to
      # Hash#merge.
      def prepend_changes(changes)
        changes.append_changes(self)
      end

      # Destructively prepends a given hash of changes onto an existing hash of changes.
      def prepend_changes!(changes)
        replace(prepend_changes(changes))
      end

      # Reverses the array values of a hash of changes. Useful for rejournal both backward and
      # forward through a record's history of changes.
      def reverse_changes
        inject({}) { |nc, (a, c)| nc.merge!(a => c.reverse) }
      end

      # Destructively reverses the array values of a hash of changes.
      def reverse_changes!
        replace(reverse_changes)
      end
    end
  end
end
