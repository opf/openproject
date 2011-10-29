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

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    files = ['lib/**/*.rb', 'app/**/*.rb']
    files << Dir['vendor/plugins/**/*.rb'].reject {|f| f.match(/test/) } # Exclude test files
    t.files = files

    static_files = ['doc/CHANGELOG.rdoc',
                    'doc/COPYING.rdoc',
                    'doc/COPYRIGHT.rdoc',
                    'doc/INSTALL.rdoc',
                    'doc/RUNNING_TESTS.rdoc',
                    'doc/UPGRADING.rdoc'].join(',')

    t.options += ['--output-dir', './doc/app', '--files', static_files]
  end

rescue LoadError
  # yard not installed (gem install yard)
  # http://yardoc.org
end
