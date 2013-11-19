#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Backlogs::TaskboardCard
  class Header < CardArea
    unloadable

    def self.min_size_total
      [500, 50]
    end

    def self.pref_size_percent
      [1.0, 0.05]
    end

    def self.render(pdf, work_package, options)
      render_bounding_box(pdf, options) do

        offset = [0, pdf.bounds.height]

        work_package_identification = "#{work_package.type.name} ##{work_package.id}"

        box = text_box(pdf,
                       work_package_identification,
                       {:height => 20,
                        :at => offset,
                        :size => 20,
                        :padding_bottom => 5})

        offset[1] -= box.height
        pdf.line offset, [pdf.bounds.width, offset[1]]
      end

    end

  end
end
