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
    end

    attr_reader :document
    attr_reader :num
    attr_reader :issue
    attr_reader :type

    def initialize(issue, type, document, num)
      @document = document
      @issue = issue
      @type = type
      @num = num
    end

    def print
      row = (document.card_count % document.down) + 1
      col = ((document.card_count / document.down) % document.across) + 1
      #document.card_count += 1

      document.pdf.start_new_page if row == 1 and col == 1 and document.cards != 1

      parent_story = issue.story

      # card bounds
      document.pdf.bounding_box self.top_left(row, col), :width => document.width, :height => document.height do
        document.pdf.line_width = 0.5
        document.pdf.stroke do
          document.pdf.stroke_bounds

          # card margin
          document.pdf.bounding_box [document.inner_margin, document.height - document.inner_margin],
                            :width => document.width - (2 * document.inner_margin),
                            :height => document.height - (2 * document.inner_margin) do

            scoresize = 0
            @y = document.pdf.bounds.height
            document.pdf.font_size(12) do
              score = (type == :task ? issue.estimated_hours : issue.story_points)
              score ||= '?'
              score = "#{score} #{type == :task ? l(:label_hours) : l(:label_points)}"
              scoresize = document.pdf.width_of(" #{score} ")

              text_box(score,
                       {:width => scoresize, :height => document.pdf.font.height},
                       document.pdf.bounds.width - scoresize)
            end

            @y = document.pdf.bounds.height
            pos = parent_story.position ? parent_story.position : l(:label_not_prioritized)
            trail = (issue.self_and_ancestors.reverse.collect{|i| "#{i.tracker.name} ##{i.id}"}.join(" : ")) + " (#{pos})"
            document.pdf.font_size(6) do
              text_box(trail, :width => document.pdf.bounds.width - scoresize,
                              :height => document.pdf.font.height,
                              :style => :italic)
            end

            document.pdf.font_size(6) do
              if type == :task
                parent = parent_story.subject
              elsif issue.fixed_version
                parent = issue.fixed_version.name
              else
                parent = I18n.t(:backlogs_product_backlog)
              end

              text_box(parent, :width => document.pdf.bounds.width - scoresize,
                               :height => document.pdf.font.height)
            end

            text_box(issue.subject, :width => document.pdf.bounds.width,
                                    :height => document.pdf.font.height * 2)

            document.pdf.line [0, @y], [document.pdf.bounds.width, @y]
            @y -= 2

            document.pdf.font_size(8) do
              text_box(issue.description || issue.subject,
                       :width => document.pdf.bounds.width,
                       :height => @y - 8)
            end

            document.pdf.font_size(6) do
              category = issue.category ? "#{l(:field_category)}: #{issue.category.name}" : ''
              catsize = document.pdf.width_of(" #{category} ")

              text_box(category,
                       {:width => catsize, :height => document.pdf.font.height},
                       document.pdf.bounds.width - catsize)
            end
          end
        end
      end
    end

    def text_box(s, options, x = 0)
      box = Prawn::Text::Box.new(s, options.merge(:overflow => :ellipses, :at => [x, @y], :document => document.pdf))
      box.render
      @y -= (options[:height] + (options[:size] || document.pdf.font_size) / 2)

      box
    end

    def top_left(row, col)
      top = document.paper_height - (document.top_margin + document.vertical_pitch * (row - 1))
      left = document.left_margin + (document.horizontal_pitch * (col - 1))

      [left, top]
    end
  end
end
