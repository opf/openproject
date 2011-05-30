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

def deprecated_task(name, new_name)
  task name=>new_name do
    $stderr.puts "\nNote: The rake task #{name} has been deprecated, please use the replacement version #{new_name}"
  end
end

deprecated_task :load_default_data, "redmine:load_default_data"
deprecated_task :migrate_from_mantis, "redmine:migrate_from_mantis"
deprecated_task :migrate_from_trac, "redmine:migrate_from_trac"
