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


Dir[File.expand_path("../redmine/acts/journalized/*.rb", __FILE__)].each{|f| require f }
require "ar_condition"

module Redmine
  module Acts
    module Journalized

      def self.included(base)
        base.extend ClassMethods
        base.extend Versioned
      end

      module ClassMethods
        attr_writer :journal_class_name
        def journal_class_name
          defined?(@journal_class_name) ? @journal_class_name : superclass.journal_class_name
        end

        def plural_name
          self.name.underscore.pluralize
        end

        # A model might provide as many activity_types as it wishes.
        # Activities are just different search options for the event a model provides
        def acts_as_activity(options = {})
          activity_hash = journalized_activity_hash(options)
          type = activity_hash[:type]
          acts_as_activity_provider activity_hash
          unless Redmine::Activity.providers[type].include? self.name
            Redmine::Activity.register type.to_sym, :class_name => self.name
          end
        end

        # This call will add an activity and, if neccessary, start the journaling and
        # add an event callback on the model.
        # Versioning and acting as an Event may only be applied once.
        # To apply more than on activity, use acts_as_activity
        def acts_as_journalized(options = {}, &block)
          activity_hash, event_hash, journal_hash = split_option_hashes(options)

          self.journal_class_name = journal_hash.delete(:class_name) || "#{name.gsub("::", "_")}Journal"

          acts_as_activity(activity_hash)

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

          journal_class.acts_as_event journalized_event_hash(event_hash)

          (journal_hash[:except] ||= []) << self.primary_key << inheritance_column <<
            :updated_on << :updated_at << :lock_version << :lft << :rgt

          prepare_journaled_options(journal_hash)

          has_many :journals, journal_hash, &block
        end

        def journal_class
          if Object.const_defined?(journal_class_name)
            Object.const_get(journal_class_name)
          else
            Object.const_set(journal_class_name, Class.new(Journal)).tap do |c|
              # Run after the inherited hook to associate with the parent record.
              # This eager loads the associated project (for permissions) if possible
              if project_assoc = reflect_on_association(:project).try(:name)
                include_option = ", :include => :#{project_assoc.to_s}"
              end
              c.class_eval("belongs_to :journaled, :class_name => '#{name}' #{include_option}")
              c.class_eval("belongs_to :#{name.gsub("::", "_").underscore},
                  :foreign_key => 'journaled_id' #{include_option}")
            end
          end
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
              when k.to_s =~ /^activity_(.+)$/
                activity_hash[$1.to_sym] = v
              when k.to_s =~ /^event_(.+)$/
                event_hash[$1.to_sym] = v
              else
                journal_hash[k.to_sym] = v
              end
            end
            [activity_hash, event_hash, journal_hash]
          end

          # Merges the passed activity_hash with the options we require for
          # acts_as_journalized to work, as follows:
          # # type is the supplied or the pluralized class name
          # # timestamp is supplied or the journal's created_at
          # # author_key will always be the journal's author
          # #
          # # find_options are merged as follows:
          # # # select statement is enriched with the journal fields
          # # # journal association is added to the includes
          # # # if a project is associated with the model, this is added to the includes
          # # # the find conditions are extended to only choose journals which have the proper activity_type
          # => a valid activity hash
          def journalized_activity_hash(options)
            options.tap do |h|
              h[:type] ||= plural_name
              h[:timestamp] ||= "#{journal_class.table_name}.created_at"
              h[:author_key] ||= "#{journal_class.table_name}.user_id"

              h[:find_options] ||= {} # in case it is nil
              h[:find_options] = {}.tap do |opts|
                cond = ::ARCondition.new
                cond.add(["#{journal_class.table_name}.activity_type = ?", h[:type]])
                cond.add(h[:find_options][:conditions]) if h[:find_options][:conditions]
                opts[:conditions] = cond.conditions

                include_opts = []
                include_opts << :project if reflect_on_association(:project)
                if h[:find_options][:include]
                  include_opts += case h[:find_options][:include]
                    when Array then h[:find_options][:include]
                    else [h[:find_options][:include]]
                  end
                end
                include_opts.uniq!
                opts[:include] = [:journaled => include_opts]

                #opts[:joins] = h[:find_options][:joins] if h[:find_options][:joins]
              end
            end
          end

          # Merges the event hashes defaults with the options provided by the user
          # The defaults take their details from the journal
          def journalized_event_hash(options)
            unless options.has_key? :url
              options[:url] = Proc.new do |journal|
                { :controller => plural_name,
                  :action => 'show',
                  :id => journal.journaled_id,
                  :anchor => ("note-#{journal.anchor}" unless journal.initial?) }
              end
            end
            options[:type] ||= self.name.underscore.dasherize # Make sure the name of the journalized model and not the name of the journal is used for events
            options[:author] ||= :user
            { :description => :notes }.reverse_merge options
          end
      end

    end
  end
end
