#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require "rspec/example_disabler"

# TODO does rspec add a space randomly to the metadata?!
#      (better make the example-disabler a litte more resilient against this)
RSpec::ExampleDisabler.disable_example(
  'ProjectsController show ',
  "plugin openproject-my_project_overview overwrites routes for show."
)

RSpec::ExampleDisabler.disable_example(
  'ProjectsController show',
  "plugin openproject-my_project_overview overwrites routes for show."
)
