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

# Load the rails application
require File.expand_path('../application', __FILE__)

SimpleBenchmark.bench 'Application.initialize!' do
  # Initialize the rails application
  OpenProject::Application.initialize!
end
