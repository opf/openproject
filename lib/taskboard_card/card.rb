require 'rubygems'

module TaskboardCard
  class Card < CardArea
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

      def margin
        9
      end

      def render(pdf, issue, options)
        render_bounding_box(pdf, options.merge(:border => true, :margin => margin)) do
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
  end
end
