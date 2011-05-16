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

            x = 0
            y = document.pdf.bounds.height
            offset = [x, y]

            offset = render_header(offset)

            offset = render_top_attributes(offset)

            offset = render_description(offset)

            render_bottom_attributes(offset)
          end
        end
      end
    end

    def render_header(offset)
      document.pdf.font_size(20) do
        issue_identification = "#{issue.tracker.name} ##{issue.id}"

        offset = text_box(issue_identification,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height},
                          offset)
      end

      document.pdf.line offset, [document.pdf.bounds.width, offset[1]]

      offset
    end

    def render_top_attributes(offset)
      offset = render_space(12, offset)
      render_parent_issue(offset)
      offset = render_sprint(offset)
      render_subject(offset)
      render_effort(offset)
    end

    def render_space(font_size, offset)
      document.pdf.font_size(font_size) do
        offset = [offset[0], offset[1] - document.pdf.font_size]
      end

      offset
    end

    def render_parent_issue(offset)
      document.pdf.font_size(12) do
        parent_name = issue.parent.present? ? "#{issue.parent.tracker.name} ##{issue.parent.id} #{issue.parent.subject}" : ""

        offset = text_box(parent_name,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height},
                          offset)
      end

      offset
    end

    def render_sprint(offset)
      document.pdf.font_size(12) do
        offset = text_box(issue.fixed_version.name,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height,
                           :align => :right},
                          offset)
      end

      offset
    end

    def render_subject(offset)
      document.pdf.font_size(20) do

        offset = text_box(issue.subject,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height * 2},
                          offset)
      end

      offset
    end

    def render_effort(offset)
      score = (type == :task ? issue.estimated_hours : issue.story_points)
      score ||= '?'
      score = "#{score} #{type == :task ? l(:label_hours) : l(:label_points)}"

      document.pdf.font_size(20) do
        offset = text_box(score,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height * 1,
                           :align => :right},
                          offset)
      end

      offset
    end

    def render_description(offset)
      document.pdf.font_size(20) do
        description = issue.description ? issue.description : ""

        offset = text_box(description,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height * 3},
                          offset)
      end

      offset
    end

    def render_bottom_attributes(offset)
      render_assigned_to(offset)
      offset = render_category(offset)
      render_sub_issues(offset)
    end

    def render_assigned_to(offset)
      document.pdf.font_size(12) do
        assigned_to = "#{l(:field_assigned_to)}: #{issue.assigned_to}"

        offset = text_box(assigned_to,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height * 1},
                          offset)
      end

      offset
    end

    def render_category(offset)
      document.pdf.font_size(12) do
        category = "#{l(:field_category)}: #{issue.category}"

        offset = text_box(category,
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height * 1,
                           :align => :right},
                          offset)
      end

      offset
    end

    def render_sub_issues(offset)
      document.pdf.font_size(12) do
        offset = text_box("#{l(:label_subtask_plural)}:",
                          {:width => document.pdf.bounds.width,
                           :height => document.pdf.font.height},
                          offset)

        issue.children.each do |child|
          offset = text_box("#{child.tracker.name} ##{child.id} #{child.subject}",
                            {:width => document.pdf.bounds.width,
                             :height => document.pdf.font.height * 1},
                            offset)
        end
      end

      offset
    end

    def text_box(text, options, offset = [0, 0])
      box = Prawn::Text::Box.new(text, options.merge(:overflow => :ellipses, :at => offset, :document => document.pdf))
      box.render
      [0, offset[1] - (options[:height] + (options[:size] || document.pdf.font_size) / 2)]
    end

    def top_left(row, col)
      top = document.paper_height - (document.top_margin + document.vertical_pitch * (row - 1))
      left = document.left_margin + (document.horizontal_pitch * (col - 1))

      [left, top]
    end
  end
end
