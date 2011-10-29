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

module Redmine #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      # Custom string inflections
      module Inflections
        def with_leading_slash
          starts_with?('/') ? self : "/#{ self }"
        end
      end
    end
  end
end
