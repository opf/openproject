require 'prawn'
require 'prawn/measurement_extensions'

module TaskboardCard
  class Document
    unloadable

    include Redmine::I18n

    attr_reader :pdf
    attr_reader :paper_width
    attr_reader :paper_height
    attr_reader :top_margin
    attr_reader :vertical_pitch
    attr_reader :height
    attr_reader :left_margin
    attr_reader :inner_margin
    attr_reader :horizontal_pitch
    attr_reader :width
    attr_reader :across
    attr_reader :down
    attr_reader :issues

    def initialize(lang)
      set_language_if_valid lang

      raise "No label stock selected" unless Setting.plugin_redmine_backlogs[:card_spec]
      label = Page.selected_label
      raise "Label stock \"#{Setting.plugin_redmine_backlogs[:card_spec]}\" not found" unless label

      label['papersize'].upcase!

      geom = Prawn::Document::PageGeometry::SIZES[label['papersize']]
      raise "Paper size '#{label['papersize']}' not supported" if geom.nil?

      page_layout = :landscape

      if page_layout == :portrait
        @paper_width = geom[0]
        @paper_height = geom[1]
        @top_margin = Card.topts(label['top_margin'])
        @vertical_pitch = Card.topts(label['vertical_pitch'])
        @height = Card.topts(label['height'])

        @left_margin = Card.topts(label['left_margin'])
        @horizontal_pitch = Card.topts(label['horizontal_pitch'])
        @width = Card.topts(label['width'])
      else
        @paper_width = geom[1]
        @paper_height = geom[0]
        @left_margin = Card.topts(label['top_margin'])
        @horizontal_pitch = Card.topts(label['vertical_pitch'])
        @width = Card.topts(label['height'])

        @top_margin = Card.topts(label['left_margin'])
        @vertical_pitch = Card.topts(label['horizontal_pitch'])
        @height = Card.topts(label['width'])
      end

      @across = label['across']
      @down = label['down']

      @inner_margin = Card.topts(label['inner_margin']) || 1.mm

      @pdf = Prawn::Document.new(
        :page_layout => page_layout,
        :left_margin => 0,
        :right_margin => 0,
        :top_margin => 0,
        :bottom_margin => 0,
        :page_size => label['papersize'])

      fontdir = File.dirname(__FILE__) + '/ttf'
      @pdf.font_families.update(
        "DejaVuSans" => {
          :bold         => "#{fontdir}/DejaVuSans-Bold.ttf",
          :italic       => "#{fontdir}/DejaVuSans-Oblique.ttf",
          :bold_italic  => "#{fontdir}/DejaVuSans-BoldOblique.ttf",
          :normal       => "#{fontdir}/DejaVuSans.ttf"
        }
      )
      @pdf.font "DejaVuSans"

      @issues = []
    end

    def add_story(story, add_tasks = true)
      add_issue(story)

      if add_tasks
        story.tasks.each do |task|
          add_issue(task)
        end
      end
    end

    def add_issue(story)
      self.issues << story
    end

    def render
      render_cards
      self.pdf.render
    end

    def render_cards
      self.issues.each_with_index do |issue, i|
        row = (i % self.down) + 1
        col = ((i / self.down) % self.across) + 1

        self.pdf.start_new_page if row == 1 and col == 1 and self.issues != 1

        Card.render(pdf, issue, {:height => self.paper_height,
                                 :width => self.paper_width,
                                 :at => card_top_left(row, col)})
      end
    end

    def card_top_left(row, col)
      top = self.paper_height - (self.top_margin + self.vertical_pitch * (row - 1))
      left = self.left_margin + (self.horizontal_pitch * (col - 1))

      [left, top]
    end
  end
end