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
