#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'rails/generators'

class Generators::OpenProject::Plugin::PluginGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :plugin_name, type: :string, default: 'openproject-new-plugin'
  argument :root_folder, type: :string, default: 'vendor/gems'

  # every public method is run when the generator is invoked
  def generate_plugin
    plugin_dir
    lib_dir
    bin_dir
  end

  def full_name
    @full_name ||= begin
      "openproject-#{plugin_name}"
    end
  end

  private

  def raise_on_params
    puts plugin_name
    puts root_folder
  end

  def plugin_path
    "#{root_folder}/openproject-#{plugin_name}"
  end

  def plugin_dir
    @plugin_dir ||= begin
      directory('', plugin_path, recursive: false)
    end
  end

  def lib_path
    "#{plugin_path}/lib"
  end

  def lib_dir
    @lib_dir ||= begin
      directory('lib', lib_path)
    end
  end

  def bin_path
    "#{plugin_path}/bin"
  end

  def bin_dir
    @bin_dir ||= begin
      directory('bin', bin_path)
    end
  end
end
