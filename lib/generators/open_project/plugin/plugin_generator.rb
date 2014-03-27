#-- copyright
# OpenProject Plugins Plugin
#
# Copyright (C) 2013 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

class OpenProject::PluginGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :plugin_name, :type => :string, :default => "openproject-new-plugin"
  argument :root_folder, :type => :string, :default => "vendor/gems"

  # every public method is run when the generator is invoked
  def generate_plugin
    plugin_dir
    lib_dir
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
      directory('', plugin_path, :recursive => false)
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
end
