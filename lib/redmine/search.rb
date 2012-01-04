#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module Search

    mattr_accessor :available_search_types

    @@available_search_types = []

    class << self
      def map(&block)
        yield self
      end

      # Registers a search provider
      def register(search_type, options={})
        search_type = search_type.to_s
        @@available_search_types << search_type unless @@available_search_types.include?(search_type)
      end
    end

    module Controller
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        @@default_search_scopes = Hash.new {|hash, key| hash[key] = {:default => nil, :actions => {}}}
        mattr_accessor :default_search_scopes

        # Set the default search scope for a controller or specific actions
        # Examples:
        #   * search_scope :issues # => sets the search scope to :issues for the whole controller
        #   * search_scope :issues, :only => :index
        #   * search_scope :issues, :only => [:index, :show]
        def default_search_scope(id, options = {})
          if actions = options[:only]
            actions = [] << actions unless actions.is_a?(Array)
            actions.each {|a| default_search_scopes[controller_name.to_sym][:actions][a.to_sym] = id.to_s}
          else
            default_search_scopes[controller_name.to_sym][:default] = id.to_s
          end
        end
      end

      def default_search_scopes
        self.class.default_search_scopes
      end

      # Returns the default search scope according to the current action
      def default_search_scope
        @default_search_scope ||= default_search_scopes[controller_name.to_sym][:actions][action_name.to_sym] ||
                                  default_search_scopes[controller_name.to_sym][:default]
      end
    end
  end
end
