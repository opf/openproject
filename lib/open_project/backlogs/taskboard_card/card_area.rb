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
  class CardArea
    unloadable

    def self.pref_size_percent
      raise NotImplementedError.new('Subclasses need to implement this methods')
    end

    def self.text_box(pdf, text, options)
      options = adapted_text_box_options(pdf, text, options)
      text = abbreviate_text(pdf, text, options)

      pdf.text_box(text, options)

      Box.new(options[:at][0], options[:at][1], options[:width], options[:height] + options[:padding_bottom])
    end

    def self.render_bounding_box(pdf, options)
      opts = { :width => pdf.bounds.width }
      offset = options[:at] || [0, pdf.bounds.height]

      pdf.bounding_box(offset, opts.merge(options)) do

        pdf.stroke_bounds if options[:border]

        if options[:margin]
          pdf.bounding_box([options[:margin], pdf.bounds.height - options[:margin]],
                          :width => pdf.bounds.width - (2 * options[:margin]),
                          :height => pdf.bounds.height - (2 * options[:margin])) do

            yield
          end
        else
          yield
        end
      end
    end

    def self.min_size
      [0, 0]
    end

    def self.margin
      0
    end

    def self.render(pdf, work_package, offset)
      raise NotImplementedError.new('Subclasses need to implement this methods')
    end

    def self.strip_tags(string)
      ActionController::Base.helpers.strip_tags(string)
    end

    private

    def self.adapted_text_box_options(pdf, text, options)
      align = options.delete(:align)
      if align == :right
        options[:width] = pdf.width_of(text, options)
        options[:at][0] = pdf.bounds.width - options[:width]
      end

      opts = {:width => pdf.bounds.width,
              :padding_bottom => 10,
              :document => pdf}

      opts.merge(options)
    end

    def self.abbreviate_text(pdf, text, options)
      text_box = Prawn::Text::Box.new(text, options)
      left_over = text_box.render(:dry_run => true)

      # Be sure to do length arithmetics on chars, not bytes!
      left_over = left_over.mb_chars
      text      = text.to_s.mb_chars

      text = left_over.size > 0 ? text[0 ... -(left_over.size + 5)] + "[...]" : text
      text.to_s
    rescue Prawn::Errors::CannotFit
      ''
    end
  end
end
