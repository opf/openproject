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


def deprecated_task(name, new_name)
  task name=>new_name do
    $stderr.puts "\nNote: The rake task #{name} has been deprecated, please use the replacement version #{new_name}"
  end
end

def removed_task(name, message)
  task name do
    $stderr.puts "\nError: The rake task #{name} has been removed. #{message}"
    raise
  end
end

deprecated_task :load_default_data, "redmine:load_default_data"

plugin_migrate_message = "<plugin>:install:migrations is used now to copy" +
                         " migrations to the rails application directory." +
                         " After installation, use db:migrate."
removed_task "db:migrate_plugins", plugin_migrate_message
removed_task "db:migrate:plugin", plugin_migrate_message
removed_task "redmine:plugins:migrate", plugin_migrate_message
