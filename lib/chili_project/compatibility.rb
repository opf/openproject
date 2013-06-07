#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
  end
end
