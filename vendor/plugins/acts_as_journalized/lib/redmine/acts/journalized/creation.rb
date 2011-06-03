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
        extend ClassMethods
        include InstanceMethods

        after_save :create_journal, :if => :create_journal?

        class << self
          alias_method_chain :prepare_journaled_options, :creation
        end
      end
    end

    # Class methods added to ActiveRecord::Base to facilitate the creation of new journals.
    module ClassMethods
      # Overrides the basal +prepare_journaled_options+ method defined in VestalVersions::Options
      # to extract the <tt>:only</tt> and <tt>:except</tt> options into +vestal_journals_options+.
      def prepare_journaled_options_with_creation(options)
        result = prepare_journaled_options_without_creation(options)

        self.vestal_journals_options[:only] = Array(options.delete(:only)).map(&:to_s).uniq if options[:only]
        self.vestal_journals_options[:except] = Array(options.delete(:except)).map(&:to_s).uniq if options[:except]

        result
      end
    end

    # Instance methods that determine whether to save a journal and actually perform the save.
    module InstanceMethods
      private
        # Returns whether a new journal should be created upon updating the parent record.
        # A new journal will be created if
        # a) attributes have changed
        # b) no previous journal exists
        # c) journal notes were added
        # d) the parent record is already saved
        def create_journal?
          update_journal
          (journal_changes.present? or journal_notes.present? or journals.empty?) and !new_record?
        end

        # Creates a new journal upon updating the parent record.
        # "update_journal" has been called in "update_journal?" at this point (to get a hold on association changes)
        # It must not be called again here.
        def create_journal
          journals << self.class.journal_class.create(journal_attributes)
          reset_journal_changes
          reset_journal
          true
        rescue Exception => e # FIXME: What to do? This likely means that the parent record is invalid!
          p e
          p e.message
          p e.backtrace
          false
        end

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
          attributes = { :journaled_id => self.id, :activity_type => activity_type, 
            :changes => journal_changes, :version => last_version + 1,
            :notes => journal_notes, :user_id => (journal_user.try(:id) || User.current.try(:id)) }
        end
    end
  end
end
