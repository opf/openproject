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

Then /^"(.+)" should be disabled in the my project page available widgets drop down$/ do |widget_name|
  option_name = MyProjectsOverviewsController.available_blocks.detect{|_k, v| I18n.t(v) == widget_name}.first.dasherize

  steps %Q{Then the "block-select" drop-down should have the following options disabled:
            | #{option_name} |}
end
