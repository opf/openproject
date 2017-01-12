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
# This file is part of the acts_as_journalized plugin for the redMine
# project management software
#
# Copyright (C) 2010  Finn GmbH, http://finn.de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
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

Dir[File.expand_path('../redmine/acts/journalized/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../acts/journalized/*.rb', __FILE__)].each { |f| require f }
require 'ar_condition'

module Redmine
  module Acts
    module Journalized
      def self.included(base)
        base.extend ClassMethods
        base.extend Versioned
      end

      module ClassMethods
        def plural_name
          name.underscore.pluralize
        end

        # This call will add an activity and, if neccessary, start the journaling and
        # add an event callback on the model.
        # Versioning and acting as an Event may only be applied once.
        # To apply more than on activity, use acts_as_activity
        def acts_as_journalized(options = {}, &block)
          activity_hash, event_hash, journal_hash = split_option_hashes(options)

          return if journaled?

          include Options
          include Changes
          include Creation
          include Users
          include Reversion
          include Reset
          include Reload
          include Permissions
          include SaveHooks
          include FormatHooks

          # FIXME: When the transition to the new API is complete, remove me
          include Deprecated

          (journal_hash[:except] ||= []) << primary_key << inheritance_column <<
            :updated_on << :updated_at << :lock_version << :lft << :rgt

          journal_hash = prepare_journaled_options(journal_hash)

          has_many :journals, -> {
            order("#{Journal.table_name}.version ASC")
          }, journal_hash, &block
        end

        private

        # Splits an option has into three hashes:
        ## => [{ options prefixed with "activity_" }, { options prefixed with "event_" }, { other options }]
        def split_option_hashes(options)
          activity_hash = {}
          event_hash = {}
          journal_hash = {}

          options.each_pair do |k, v|
            case
            when k.to_s =~ /\Aactivity_(.+)\z/
              activity_hash[$1.to_sym] = v
            when k.to_s =~ /\Aevent_(.+)\z/
              event_hash[$1.to_sym] = v
            else
              journal_hash[k.to_sym] = v
            end
          end
          [activity_hash, event_hash, journal_hash]
        end

        # Merges the event hashes defaults with the options provided by the user
        # The defaults take their details from the journal
        def journalized_event_hash(options)
          unless options.has_key? :url
            options[:url] = Proc.new do |data|
              { controller: plural_name,
                action: 'show',
                id: data.journal.journable_id,
                anchor: ("note-#{data.journal.anchor}" unless data.journal.initial?) }
            end
          end
          options[:type] ||= name.underscore.dasherize # Make sure the name of the journalized model and not the name of the journal is used for events
          options[:author] ||= :user
          { description: :notes }.reverse_merge options
        end
      end
    end
  end
end
