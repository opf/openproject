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

module Redmine
  module Scm
    class Base
      class << self

        def all
          @scms
        end

        # Add a new SCM adapter and repository
        def add(scm_name)
          @scms ||= []
          @scms << scm_name
        end

        # Remove a SCM adapter from Redmine's list of supported scms
        def delete(scm_name)
          @scms.delete(scm_name)
        end
      end
    end
  end
end
