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
  class BottomAttributes < CardArea
    unloadable

    include Redmine::I18n

    class << self
      def min_size_total
        [500, 200]
      end

      def pref_size_percent
        [1.0, 0.3]
      end

      def margin
        9
      end

      def render(pdf, work_package, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do

          category_box = render_category(pdf, work_package, {:at => [0, pdf.bounds.height],
                                                      :align => :right})

          assigned_to_box = render_assigned_to(pdf, work_package, {:at => [0, category_box.y],
                                                            :width => pdf.bounds.width - category_box.width,
                                                            :padding_bottom => 20})

          render_sub_work_packages(pdf, work_package, {:at => [0, assigned_to_box.y - assigned_to_box.height]})
        end
      end


      def render_assigned_to(pdf, work_package, options)

        assigned_to = "#{WorkPackage.human_attribute_name(:assigned_to)}: #{work_package.assigned_to ? work_package.assigned_to : "-"}"

        text_box(pdf,
                 assigned_to,
                 {:width => pdf.bounds.width,
                  :height => 12,
                  :size => 12}.merge(options))
      end

      def render_category(pdf, work_package, options)

        category = "#{WorkPackage.human_attribute_name(:category)}: #{work_package.category ? work_package.category : "-"}"

        text_box(pdf,
                 category,
                 {:width => pdf.bounds.width,
                  :height => 12}.merge(options))

      end

      def render_sub_work_packages(pdf, work_package, options)
        at = options.delete(:at)
        box = Box.new(at[0], at[1], 0, 0)

        pdf.font_size(12) do
          temp_box = text_box(pdf,
                              "#{l(:label_subtask_plural)}: #{work_package.children.size == 0 ? "-" : ""}",
                              {:height => pdf.font.height,
                               :at => box.at,
                               :paddint_bottom => 6})

          box.height += temp_box.height
          box.width = temp_box.width

          work_package.children.each_with_index do |child, i|

            if box.height + pdf.font.height > pdf.font.height ||  work_package.children.size - i == 1
              temp_box = text_box(pdf,
                                "#{child.type.name} ##{child.id}: #{child.subject}",
                                {:height => pdf.font.height,
                                 :at => [10, at[1] - box.height],
                                 :padding_bottom => 3})
            else
              temp_box = text_box(pdf,
                                l('backlogs.x_more', :count => work_package.children.size - i),
                                :height => pdf.font.height,
                                :at => [10, at[1] - box.height])
              break
            end

            box.height += temp_box.height
          end
        end

        box
      end

    end

  end
end
