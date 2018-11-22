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


FactoryBot.define do
  factory :export_card_configuration do
    name { "Config 1" }
    description { "This is a description" }
    rows { "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false" }
    per_page { 5 }
    page_size { "A4" }
    orientation { "landscape" }
  end

  factory :default_export_card_configuration, :class => ExportCardConfiguration do
    name { "Default" }
    description { "This is a description" }
    active { true }
    rows { "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false" }
    per_page { 5 }
    page_size { "A4" }
    orientation { "landscape" }
  end

  factory :invalid_export_card_configuration, :class => ExportCardConfiguration do
    name { "Invalid" }
    description { "This is a description" }
    rows { "row1" }
    per_page { "string" }
    page_size { "asdf" }
    orientation { "qwer" }
  end

  factory :active_export_card_configuration, :class => ExportCardConfiguration do
    name { "Config active" }
    description { "This is a description" }
    active { true }
    rows { "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false" }
    per_page { 5 }
    page_size { "A4" }
    orientation { "landscape" }
  end

  factory :inactive_export_card_configuration, :class => ExportCardConfiguration do
    name { "Config inactive" }
    description { "This is a description" }
    active { false }
    rows { "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false" }
    per_page { 5 }
    page_size { "A4" }
    orientation { "landscape" }
  end
end
