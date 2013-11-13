#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Team
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
  class TopAttributes < CardArea
    unloadable
    include Redmine::I18n

    class << self
      def min_size_total
        [500, 100]
      end

      def pref_size_percent
        [1.0, 0.1]
      end

      def margin
        9
      end

      def render(pdf, work_package, options)
         render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

           sprint_box = render_sprint(pdf, work_package, {:at => [0, pdf.bounds.height],
                                                   :align => :right})

           render_parent_work_package(pdf, work_package, {:at => [0, sprint_box.y],
                                            :width => pdf.bounds.width - sprint_box.width})

           effort_box = render_effort(pdf, work_package, {:at => [0, pdf.bounds.height - sprint_box.height],
                                                   :align => :right})

           render_subject(pdf, work_package, {:at => [0, effort_box.y],
                                       :width => pdf.bounds.width - effort_box.width})
         end
       end

      def render_parent_work_package(pdf, work_package, options)
        parent_name = work_package.parent.present? ? "#{work_package.parent.type.name} ##{work_package.parent.id}: #{work_package.parent.subject}" : ""

        text_box(pdf,
                 parent_name,
                 {:height => 12,
                  :size => 12}.merge(options))
      end

      def render_sprint(pdf, work_package, options)
        name = work_package.fixed_version ? work_package.fixed_version.name : "-"

        text_box(pdf,
                 name,
                 {:height => 12,
                  :size => 12}.merge(options))
      end

      def render_subject(pdf, work_package, options)
        text_box(pdf,
                 work_package.subject,
                 {:height => 20,
                  :size => 20}.merge(options))
      end

      def render_effort(pdf, work_package, options)
        type = work_package.is_task?
        score = (type == :task ? work_package.estimated_hours : work_package.story_points)
        score ||= '-'
        score = "#{score} #{type == :task ? l(:label_hours) : l(:label_points)}"

        text_box(pdf,
                 score,
                 {:height => 20,
                  :size => 20}.merge(options))
      end
    end
  end
end
