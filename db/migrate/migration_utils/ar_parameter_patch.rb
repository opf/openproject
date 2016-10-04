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

if Rails.gem_version >= Gem::Version.new('5.0.1')
  raise <<-MESSAGE


  The patch applied to ActionController::Parameters is now part of rails itself. Check, if the patch can be removed.


  MESSAGE
end

module ArParametersPatch

  def self.load
    hook_into_yaml_loading

    ActionController::Parameters.prepend(ArParametersPatch::InitWith)
  end

  # Taken straight from https://github.com/rails/rails/compare/6b44155%5E...70b995a
  # which will become part of rails 5.1
  def self.hook_into_yaml_loading # :nodoc:
    # Wire up YAML format compatibility with Rails 4.2 and Psych 2.0.8 and 2.0.9+.
    # Makes the YAML parser call `init_with` when it encounters the keys below
    # instead of trying its own parsing routines.
    name = ActionController::Parameters.name
    YAML.load_tags["!ruby/hash-with-ivars:ActionController::Parameters"] = name
    YAML.load_tags["!ruby/hash:ActionController::Parameters"] = name
  end

  module InitWith
    def init_with(coder) # :nodoc:
      case coder.tag
      when "!ruby/hash:ActionController::Parameters"
        # YAML 2.0.8's format where hash instance variables weren't stored.
        @parameters = coder.map.with_indifferent_access
        @permitted  = false
      when "!ruby/hash-with-ivars:ActionController::Parameters"
        # YAML 2.0.9's Hash subclass format where keys and values
        # were stored under an elements hash and `permitted` within an ivars hash.
        @parameters = coder.map["elements"].with_indifferent_access
        @permitted  = coder.map["ivars"][:@permitted]
      when "!ruby/object:ActionController::Parameters"
        # YAML's Object format. Only needed because of the format
        # backwardscompability above, otherwise equivalent to YAML's initialization.
        @parameters, @permitted = coder.map["parameters"], coder.map["permitted"]
      end
    end
  end
end
