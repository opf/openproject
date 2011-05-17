require 'rubygems'

module TaskboardCard
  class Card
    unloadable

    include Redmine::I18n

    class << self
      def topts(v)
        return if v.nil?

        if v =~ /[a-z]{2}$/i
          units = v[-2, 2].downcase
          v = v[0..-3]
        else
          units = 'pt'
        end

        v = "#{v}0" if v =~ /\.$/

        return Float(v).mm if units == 'mm'
        return Float(v).cm if units == 'cm'
        return Float(v).in if units == 'in'
        return Float(v).pt if units == 'pt'
        raise "Unexpected units '#{units}'"
      end

      def areas
        [TaskboardCard::Header,
         TaskboardCard::TopAttributes,
         TaskboardCard::Description,
         TaskboardCard::BottomAttributes]
      end
    end

    attr_reader :document
    attr_reader :num
    attr_reader :issue
    attr_reader :type
    attr_reader :pdf

    def initialize(issue, type, document, num)
      @document = document
      @issue = issue
      @type = type
      @num = num
      @pdf = document.pdf
    end

    def print
      row = (document.card_count % document.down) + 1
      col = ((document.card_count / document.down) % document.across) + 1

      document.pdf.start_new_page if row == 1 and col == 1 and document.cards != 1

      # card bounds
      document.pdf.bounding_box self.top_left(row, col), :width => document.width, :height => document.height do
        document.pdf.line_width = 0.5
        document.pdf.stroke_bounds

        # card margin
        document.pdf.bounding_box [document.inner_margin, document.height - document.inner_margin],
                          :width => document.width - (2 * document.inner_margin),
                          :height => document.height - (2 * document.inner_margin) do

          margin = 10
          y_offset = pdf.bounds.height

          Card.areas.each do |card|
            height = pdf.bounds.height * card.pref_size_percent[1]
            card.render(pdf, issue, {:at => [0, y_offset],
                                            :height => height})
            y_offset -= height + margin
          end
        end
      end
    end

    def top_left(row, col)
      top = document.paper_height - (document.top_margin + document.vertical_pitch * (row - 1))
      left = document.left_margin + (document.horizontal_pitch * (col - 1))

      [left, top]
    end
  end
end
