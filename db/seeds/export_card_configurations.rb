#-- copyright
# OpenProject PDF Export Plugin
#
# Copyright (C)2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject PDF Export Plugin is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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


if ExportCardConfiguration.find_by_identifier("default").nil?
  ExportCardConfiguration.create({name: "Default",
    per_page: 2,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n  row1:\n    has_border: false\n    columns:\n      id:\n        has_label: false\n        font_size: 20\n        font_style: bold\n        priority: 1\n        minimum_lines: 2\n        render_if_empty: false\n        width: 30%\n      due_date:\n        has_label: false\n        font_size: 15\n        font_style: italic\n        priority: 1\n        minimum_lines: 2\n        render_if_empty: false\n        width: 70%\n  row2:\n    has_border: false\n    columns:\n      description:\n        has_label: false\n        font_size: 15\n        font_style: normal\n        priority: 4\n        minimum_lines: 5\n        render_if_empty: false\n        width: 100%\n"})
end