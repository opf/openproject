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

module OpenProject::PdfExport::ExportCard
  class ColumnElement
    def initialize(pdf, property_name, config, orientation, work_package)
      @pdf = pdf
      @property_name = property_name
      @config = config
      @orientation = orientation
      @work_package = work_package
    end

    def draw
      # Get value from model
      value = @work_package.send(@property_name) if @work_package.respond_to?(@property_name) else ""

      if value.is_a?(Array)
        value = value.map{|c| c.to_s }.join("\n")
      end
      draw_value(value)
    end

    private

    def abbreviate_text(text, options)
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

    def draw_value(value)

      # Font size
      if @config['font_size']
        # Specific size given
        overflow = :truncate
        font_size = Integer(@config['font_size'])

      elsif @config['min_font_size']
        # Range given
        overflow = :shrink_to_fit
        min_font_size = Integer(@config['min_font_size'])
        font_size = if @config['max_font_size']
                      Integer(@config['max_font_size'])
                    else
                      min_font_size
                    end
      else
        # Default
        font_size = 12
        overflow = :truncate
      end

      font_style = (@config['font_style'] or "normal").to_sym
      text_align = (@config['text_align'] or "left").to_sym

      offset = [@orientation[:x_offset], @orientation[:height] - (@orientation[:text_padding] / 2)]
      options = { :document => @pdf,
       :height => @orientation[:height],
       :width => @orientation[:width],
       :at => offset,
       :style => font_style,
       :overflow => overflow,
       :size => font_size,
       :min_font_size => min_font_size,
       :align => text_align}

      # Draw on pdf
      has_label = @config['has_label']
      value = value.to_s if !value.is_a?(String)
      text = ""
      text = text + "#{@work_package.class.human_attribute_name(@property_name)}: " if has_label
      text = abbreviate_text(text + value, options)

      box = @pdf.text_box(text, options)
    end

  end
end