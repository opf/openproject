#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
  # Adds the functionality necessary to control journal creation on a journaled instance of
  # ActiveRecord::Base.
  module Creation
    def self.included(base) # :nodoc:
      base.class_eval do
        include InstanceMethods

        class << self
          prepend ClassMethods
        end
      end
    end

    # Class methods added to ActiveRecord::Base to facilitate the creation of new journals.
    module ClassMethods
      # Overrides the basal +prepare_journaled_options+ method defined in VestalVersions::Options
      # to extract the <tt>:only</tt> and <tt>:except</tt> options into +vestal_journals_options+.
      def prepare_journaled_options(options)
        result = super(options)

        vestal_journals_options[:only] = Array(result.delete(:only)).map(&:to_s).uniq if result[:only]
        vestal_journals_options[:except] = Array(result.delete(:except)).map(&:to_s).uniq if result[:except]

        result
      end
    end

    # Instance methods that determine whether to save a journal and actually perform the save.
    module InstanceMethods
      # Recreates the initial journal used to track the beginning state
      # of the object. Useful for objects that didn't have an initial journal
      # created (e.g. legacy data)
      def recreate_initial_journal!
        new_journal = journals.find_by(version: 1)
        new_journal ||= journals.build

        initial_changes = {}

        JournalManager.journal_class(self.class).journaled_attributes.each do |name|
          # Set the current attributes as initial attributes
          # This works as a fallback if no prior change is found
          initial_changes[name] = send(name)

          # Try to find the real initial values
          unless journals.empty?
            journals[1..-1].each do |journal|
              unless journal.details[name].nil?
                # Found the first change in journals
                # Copy the first value as initial change value
                initial_changes[name] = journal.details[name].first
                break
              end
            end
          end
        end

        fill_object = self.class.new

        # Force the gathered attributes onto the fill object
        # FIX ME: why not just call the method directly on fill_object?
        attributes_setter = ActiveRecord::Base.instance_method(:assign_attributes)
        attributes_setter = attributes_setter.bind(fill_object)

        attributes_setter.call(initial_changes)

        # Call the journal creating method
        changed_data = fill_object.send(:merge_journal_changes)

        new_journal.version = 1
        new_journal.activity_type = activity_type

        if respond_to?(:author)
          new_journal.user_id = author.id
        elsif respond_to?(:user)
          new_journal.user_id = user.id
        end

        JournalManager.recreate_initial_journal self.class, new_journal, changed_data

        # Backdate journal
        if respond_to?(:created_at)
          new_journal.update_attribute(:created_at, created_at)
        elsif respond_to?(:created_on)
          new_journal.update_attribute(:created_at, created_on)
        end
        new_journal
      end

      private

      # Returns an array of column names that should be included in the changes of created
      # journals. If <tt>vestal_journals_options[:only]</tt> is specified, only those columns
      # will be journaled. Otherwise, if <tt>vestal_journals_options[:except]</tt> is specified,
      # all columns will be journaled other than those specified. Without either option, the
      # default is to journal all columns. At any rate, the four "automagic" timestamp columns
      # maintained by Rails are never journaled.
      def journaled_columns
        case
        when vestal_journals_options[:only] then self.class.column_names & vestal_journals_options[:only]
        when vestal_journals_options[:except] then self.class.column_names - vestal_journals_options[:except]
        else self.class.column_names
        end - %w(created_at updated_at)
      end

      # Returns the activity type. Should be overridden in the journalized class to offer
      # multiple types
      def activity_type
        self.class.name.underscore.pluralize
      end

      # Specifies the attributes used during journal creation. This is separated into its own
      # method so that it can be overridden by the VestalVersions::Users feature.
      def journal_attributes
        { journaled_id: id, activity_type: activity_type,
          details: journal_changes, version: last_version + 1,
          notes: journal_notes, user_id: (journal_user.try(:id) || User.current.try(:id))
        }.merge(extra_journal_attributes || {})
      end
    end
  end
end
