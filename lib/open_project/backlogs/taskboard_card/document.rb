require 'prawn'

module OpenProject::Backlogs::TaskboardCard
  class Document
    unloadable

    include Redmine::I18n
    include Measurement

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
    attr_reader :work_packages

    def initialize(lang)
      set_language_if_valid lang

      raise "No label stock selected" unless Setting.plugin_openproject_backlogs["card_spec"]
      label = PageLayout.selected_label
      raise "Label stock \"#{Setting.plugin_openproject_backlogs["card_spec"]}\" not found" unless label

      label['papersize'].upcase!

      geom = Prawn::Document::PageGeometry::SIZES[label['papersize']]
      raise "Paper size '#{label['papersize']}' not supported" if geom.nil?

      page_layout = :landscape

      if page_layout == :portrait
        @paper_width = geom[0]
        @paper_height = geom[1]
        @top_margin = Document.to_pts(label['top_margin'])
        @vertical_pitch = Document.to_pts(label['vertical_pitch'])
        @height = Document.to_pts(label['height'])

        @left_margin = Document.to_pts(label['left_margin'])
        @horizontal_pitch = Document.to_pts(label['horizontal_pitch'])
        @width = Document.to_pts(label['width'])
      else
        @paper_width = geom[1]
        @paper_height = geom[0]
        @left_margin = Document.to_pts(label['top_margin'])
        @horizontal_pitch = Document.to_pts(label['vertical_pitch'])
        @width = Document.to_pts(label['height'])

        @top_margin = Document.to_pts(label['left_margin'])
        @vertical_pitch = Document.to_pts(label['horizontal_pitch'])
        @height = Document.to_pts(label['width'])
      end

      @across = label['across']
      @down = label['down']

      @inner_margin = Document.to_pts(label['inner_margin']) || 1.mm

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

      @work_packages = []
    end

    def add_story(story, add_tasks = true)
      add_work_package(story)

      if add_tasks
        story.tasks.each do |task|
          add_work_package(task)
        end
      end
    end

    def render
      render_cards
      self.pdf.render
    end

    private

    def add_work_package(story)
      self.work_packages << story
    end

    def render_cards
      self.work_packages.each_with_index do |work_package, i|
        row = (i % self.down) + 1
        col = ((i / self.down) % self.across) + 1

        self.pdf.start_new_page if row == 1 and col == 1 and i != 0

        Card.render(pdf, work_package, {:height => self.height,
                                 :width => self.width,
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
