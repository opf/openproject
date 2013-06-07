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

require 'fileutils'

desc "Package up a ChiliProject release from git. example: `rake release[1.1.0]`"
task :release, [:version] do |task, args|
  version = args[:version]
  abort "Missing version in the form of 1.0.0" unless version.present?

  dir = Pathname.new(ENV['HOME']) + 'dev' + 'chiliproject' + 'packages'
  FileUtils.mkdir_p dir

  commands = [
              "cd #{dir}",
              "git clone git://github.com/chiliproject/chiliproject.git chiliproject-#{version}",
              "cd chiliproject-#{version}/",
              "git checkout v#{version}",
              "rm -vRf #{dir}/chiliproject-#{version}/.git",
              "cd #{dir}",
              "tar -zcvf chiliproject-#{version}.tar.gz chiliproject-#{version}",
              "zip -r -9 chiliproject-#{version}.zip chiliproject-#{version}",
              "md5sum chiliproject-#{version}.tar.gz chiliproject-#{version}.zip > chiliproject-#{version}.md5sum",
              "echo 'Release ready'"
             ].join(' && ')
  system(commands)
end
