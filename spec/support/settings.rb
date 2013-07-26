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

##
# Runs block with settings specified in options.
# The original settings are restored afterwards.
def with_settings(options, &block)
  saved_settings = options.keys.inject({}) {|h, k| h[k] = Setting[k].dup; h}
  options.each {|k, v| Setting[k] = v}
  yield
ensure
  saved_settings.each {|k, v| Setting[k] = v}
end
