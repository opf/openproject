#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ChiliProject
  class Compatibility
    # Is acts_as_journalized included?
    #
    # Released: ChiliProject 2.0.0
    def self.using_acts_as_journalized?
      Journal.included_modules.include?(Redmine::Acts::Journalized)
    end

    # Is any jQuery version available on all pages?
    #
    # This does not take modifications into account, that may be performed by
    # plugins.
    #
    # Released: ChiliProject 2.5.0
    def self.using_jquery?
      true
    end

    # Is Liquid markup available?
    #
    # Released: ChiliProject 3.0.0
    def self.using_liquid?
      true
    end

    # Catch-all to be overwritten be future compatibility checks.
    def self.method_missing(method, *args)
      method.to_s.ends_with?('?') ? false : super
    end
  end
end
