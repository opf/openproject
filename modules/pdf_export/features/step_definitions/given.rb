#-- copyright
# OpenProject PDF Export Plugin
#
# Copyright (C)2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

Given /^there are multiple export card configurations$/ do
  config1 = ExportCardConfiguration.create!({
    name: "Default",
    description: "This is a description",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  config2 = ExportCardConfiguration.create!({
    name: "Custom",
    description: "This is a description",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  config3 = ExportCardConfiguration.create!({
    name: "Custom 2",
    description: "This is a description",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  config4 = ExportCardConfiguration.create!({
    name: "Custom Inactive",
    description: "This is a description",
    active: false,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  [config1, config2, config3, config4]
end

Given /^there is the default export card configuration$/ do
  config1 = ExportCardConfiguration.create!({
    name: "Default",
    description: "This is a description",
    active: true,
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false"
  })
  [config1]
end

Given /^I fill in valid YAML for export config rows$/ do
  valid_yaml = "groups:\n  rows:\n    row1:\n      columns:\n        id:\n          has_label: false"
  fill_in("export_card_configuration_rows", :with => valid_yaml)
end
