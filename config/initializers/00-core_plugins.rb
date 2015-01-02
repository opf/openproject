#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Loads the core plugins located in lib/plugins
Dir.glob(File.join(Rails.root, 'lib/plugins/*')).sort.each do |directory|
  if File.directory?(directory)
    lib = File.join(directory, 'lib')
    if File.directory?(lib)
      $:.unshift lib
      ActiveSupport::Dependencies.autoload_paths += [lib]
    end
    initializer = File.join(directory, 'init.rb')
    if File.file?(initializer)
      config = config = OpenProject::Application.config
      eval(File.read(initializer), binding, initializer)
    end
  end
end
