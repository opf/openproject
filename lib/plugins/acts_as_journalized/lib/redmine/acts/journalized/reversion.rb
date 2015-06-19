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
  # Enables versioned ActiveRecord::Base instances to revert to a previously saved version.
  module Reversion
    def self.included(base) # :nodoc:
      base.class_eval do
        include InstanceMethods
      end
    end

    # Provides the base instance methods required to revert a journaled instance.
    module InstanceMethods
      # Returns the current version number for the versioned object.
      def version
        @version ||= last_version
      end

      def last_journal
        journals.last
      end

      # some eager loading may mess up the order
      # journals.order('created_at').last will not work
      # (especially when journals already filtered)
      # thats why this method exists
      # it is impossible to incorporate this into #last_journal
      # because some logic is based on this eager loading bug/feature
      def last_loaded_journal
        if journals.loaded?
          journals.sort_by(&:version).last
        end
      end

      # Accepts a value corresponding to a specific journal record, builds a history of changes
      # between that journal and the current journal, and then iterates over that history updating
      # the object's attributes until the it's reverted to its prior state.
      #
      # The single argument should adhere to one of the formats as documented in the +at+ method of
      # VestalVersions::Versions.
      #
      # After the object is reverted to the target journal, it is not saved. In order to save the
      # object after the rejournal, use the +revert_to!+ method.
      #
      # The journal number of the object will reflect whatever journal has been reverted to, and
      # the return value of the +revert_to+ method is also the target journal number.
      def revert_to(value)
        to_number = journals.journal_at(value)

        changes_between(journal, to_number).each do |attribute, change|
          write_attribute(attribute, change.last)
        end

        reset_journal(to_number)
      end

      # Behaves similarly to the +revert_to+ method except that it automatically saves the record
      # after the rejournal. The return value is the success of the save.
      def revert_to!(value)
        revert_to(value)
        reset_journal if saved = save
        saved
      end

      # Returns a boolean specifying whether the object has been reverted to a previous journal or
      # if the object represents the latest journal in the journal history.
      def reverted?
        version != last_version
      end

      private

      # Returns the number of the last created journal in the object's journal history.
      #
      # If no associated journals exist, the object is considered at version 0.
      def last_version
        @last_version ||= journals.maximum(:version) || 0
      end

      # Clears the cached version number instance variables so that they can be recalculated.
      # Useful after a new version is created.
      def reset_journal(version = nil)
        @last_version = nil if version.nil?
        @version = version
      end
    end
  end
end
