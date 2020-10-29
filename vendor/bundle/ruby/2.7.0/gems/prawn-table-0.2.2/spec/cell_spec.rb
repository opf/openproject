# encoding: utf-8

require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")
require_relative "../lib/prawn/table"

module CellHelpers

  # Build, but do not draw, a cell on @pdf.
  def cell(options={})
    at = options[:at] || [0, @pdf.cursor]
    Prawn::Table::Cell::Text.new(@pdf, at, options)
  end

end

describe "Prawn::Table::Cell" do
  before(:each) do
    @pdf = Prawn::Document.new
  end

  describe "Prawn::Document#cell" do
    include CellHelpers

    it "should draw the cell" do
      Prawn::Table::Cell::Text.any_instance.expects(:draw).once
      @pdf.cell(:content => "text")
    end

    it "should return a Cell" do
      @pdf.cell(:content => "text").should be_a_kind_of Prawn::Table::Cell
    end

    it "accepts :content => nil in a hash" do
      @pdf.cell(:content => nil).should be_a_kind_of(Prawn::Table::Cell::Text)
      @pdf.make_cell(:content => nil).should be_a_kind_of(Prawn::Table::Cell::Text)
    end

    it "should convert nil, Numeric, and Date values to strings" do
      [nil, 123, 123.45, Date.today].each do |value|
        c = @pdf.cell(:content => value)
        c.should be_a_kind_of Prawn::Table::Cell::Text
        c.content.should == value.to_s
      end
    end

    it "should allow inline styling with a hash argument" do
      # used for table([[{:text => "...", :font_style => :bold, ...}, ...]])
      c = Prawn::Table::Cell.make(@pdf,
                                  {:content => 'hello', :font_style => :bold})
      c.should be_a_kind_of Prawn::Table::Cell::Text
      c.content.should == "hello"
      c.font.name.should == 'Helvetica-Bold'
    end

    it "should draw text at the given point plus padding, with the given " +
       "size and style" do
      @pdf.expects(:bounding_box).yields
      @pdf.expects(:move_down)
      @pdf.expects(:draw_text!).with { |text, options| text == "hello world" }

      @pdf.cell(:content => "hello world",
                :at => [10, 20],
                :padding => [30, 40],
                :size => 7,
                :font_style => :bold)
    end
  end

  describe "Prawn::Document#make_cell" do
    it "should not draw the cell" do
      Prawn::Table::Cell::Text.any_instance.expects(:draw).never
      @pdf.make_cell("text")
    end

    it "should return a Cell" do
      @pdf.make_cell("text", :size => 7).should be_a_kind_of Prawn::Table::Cell
    end
  end

  describe "#style" do
    include CellHelpers

    it "should set each property in turn" do
      c = cell(:content => "text")

      c.expects(:padding=).with(50)
      c.expects(:size=).with(7)

      c.style(:padding => 50, :size => 7)
    end

    it "ignores unknown properties" do
      c = cell(:content => 'text')

      c.style(:foobarbaz => 'frobnitz')
    end
  end

  describe "cell width" do
    include CellHelpers

    it "should be calculated for text" do
      c = cell(:content => "text")
      c.width.should == @pdf.width_of("text") + c.padding[1] + c.padding[3]
    end

    it "should be overridden by manual :width" do
      c = cell(:content => "text", :width => 400)
      c.width.should == 400
    end

    it "should incorporate padding when specified" do
      c = cell(:content => "text", :padding => [1, 2, 3, 4])
      c.width.should be_within(0.01).of(@pdf.width_of("text") + 6)
    end

    it "should allow width to be reset after it has been calculated" do
      # to ensure that if we memoize width, it can still be overridden
      c = cell(:content => "text")
      c.width
      c.width = 400
      c.width.should == 400
    end

    it "should return proper width with size set" do
      text = "text " * 4
      c = cell(:content => text, :size => 7)
      c.width.should ==
        @pdf.width_of(text, :size => 7) + c.padding[1] + c.padding[3]
    end

    it "content_width should exclude padding" do
      c = cell(:content => "text", :padding => 10)
      c.content_width.should == @pdf.width_of("text")
    end

    it "content_width should exclude padding even with manual :width" do
      c = cell(:content => "text", :padding => 10, :width => 400)
      c.content_width.should be_within(0.01).of(380)
    end

    it "should have a reasonable minimum width that can fit @content" do
      c = cell(:content => "text", :padding => 10)
      min_content_width = c.min_width - c.padding[1] - c.padding[3]

      @pdf.height_of("text", :width => min_content_width).should be <
        (5 * @pdf.height_of("text"))
    end

    it "should defer min_width's evaluation of padding" do
      c = cell(:content => "text", :padding => 100)
      c.padding = 0

      # Make sure we use the new value of padding in calculating min_width
      c.min_width.should be < 100
    end

    it "should defer min_width's evaluation of size" do
      c = cell(:content => "text", :size => 50)
      c.size = 8
      c.padding = 0
      c.min_width.should be < 10
    end

  end

  describe "cell height" do
    include CellHelpers

    it "should be calculated for text" do
      c = cell(:content => "text")
      c.height.should ==
        @pdf.height_of("text", :width => @pdf.width_of("text")) +
        c.padding[0] + c.padding[3]
    end

    it "should be overridden by manual :height" do
      c = cell(:content => "text", :height => 400)
      c.height.should == 400
    end

    it "should incorporate :padding when specified" do
      c = cell(:content => "text", :padding => [1, 2, 3, 4])
      c.height.should be_within(0.01).of(1 + 3 +
        @pdf.height_of("text", :width => @pdf.width_of("text")))
    end

    it "should allow height to be reset after it has been calculated" do
      # to ensure that if we memoize height, it can still be overridden
      c = cell(:content => "text")
      c.height
      c.height = 400
      c.height.should == 400
    end

    it "should return proper height for blocks of text" do
      content = "words " * 10
      c = cell(:content => content, :width => 100)
      c.height.should == @pdf.height_of(content, :width => 100) +
        c.padding[0] + c.padding[2]
    end

    it "should return proper height for blocks of text with size set" do
      content = "words " * 10
      c = cell(:content => content, :width => 100, :size => 7)

      correct_content_height = nil
      @pdf.font_size(7) do
        correct_content_height = @pdf.height_of(content, :width => 100)
      end

      c.height.should == correct_content_height + c.padding[0] + c.padding[2]
    end

    it "content_height should exclude padding" do
      c = cell(:content => "text", :padding => 10)
      c.content_height.should == @pdf.height_of("text")
    end

    it "content_height should exclude padding even with manual :height" do
      c = cell(:content => "text", :padding => 10, :height => 400)
      c.content_height.should be_within(0.01).of(380)
    end
  end

  describe "cell padding" do
    include CellHelpers

    it "should default to zero" do
      c = cell(:content => "text")
      c.padding.should == [5, 5, 5, 5]
    end

    it "should accept a numeric value, setting all padding" do
      c = cell(:content => "text", :padding => 10)
      c.padding.should == [10, 10, 10, 10]
    end

    it "should accept [v,h]" do
      c = cell(:content => "text", :padding => [20, 30])
      c.padding.should == [20, 30, 20, 30]
    end

    it "should accept [t,h,b]" do
      c = cell(:content => "text", :padding => [10, 20, 30])
      c.padding.should == [10, 20, 30, 20]
    end

    it "should accept [t,l,b,r]" do
      c = cell(:content => "text", :padding => [10, 20, 30, 40])
      c.padding.should == [10, 20, 30, 40]
    end

    it "should reject other formats" do
      lambda{
        cell(:content => "text", :padding => [10])
      }.should raise_error(ArgumentError)
    end
  end

  describe "background_color" do
    include CellHelpers

    it "should fill a rectangle with the given background color" do
      @pdf.stubs(:mask).yields
      @pdf.expects(:mask).with(:fill_color).yields

      @pdf.stubs(:fill_color)
      @pdf.expects(:fill_color).with('123456')
      @pdf.expects(:fill_rectangle).checking do |(x, y), w, h|
        x.should be_within(0.01).of(0)
        y.should be_within(0.01).of(@pdf.cursor)
        w.should be_within(0.01).of(29.344)
        h.should be_within(0.01).of(23.872)
      end
      @pdf.cell(:content => "text", :background_color => '123456')
    end

    it "should draw the background in the right place if cell is drawn at a " +
       "different location" do
      @pdf.stubs(:mask).yields
      @pdf.expects(:mask).with(:fill_color).yields

      @pdf.stubs(:fill_color)
      @pdf.expects(:fill_color).with('123456')
      @pdf.expects(:fill_rectangle).checking do |(x, y), w, h|
        x.should be_within(0.01).of(12.0)
        y.should be_within(0.01).of(34.0)
        w.should be_within(0.01).of(29.344)
        h.should be_within(0.01).of(23.872)
      end
      c = @pdf.make_cell(:content => "text", :background_color => '123456')
      c.draw([12.0, 34.0])
    end
  end

  describe "color" do
    it "should set fill color when :text_color is provided" do
      pdf = Prawn::Document.new
      pdf.stubs(:fill_color)
      pdf.expects(:fill_color).with('555555')
      pdf.cell :content => 'foo', :text_color => '555555'
    end

    it "should reset the fill color to the original one" do
      pdf = Prawn::Document.new
      pdf.fill_color = '333333'
      pdf.cell :content => 'foo', :text_color => '555555'
      pdf.fill_color.should == '333333'
    end
  end

  describe "Borders" do
    it "should draw all borders by default" do
      @pdf.expects(:stroke_line).times(4)
      @pdf.cell(:content => "text")
    end

    it "should draw all borders when requested" do
      @pdf.expects(:stroke_line).times(4)
      @pdf.cell(:content => "text", :borders => [:top, :right, :bottom, :left])
    end

    # Only roughly verifying the integer coordinates so that we don't have to
    # do any FP closeness arithmetic. Can plug in that math later if this goes
    # wrong.
    it "should draw top border when requested" do
      @pdf.expects(:stroke_line).checking do |from, to|
        @pdf.map_to_absolute(from).map{|x| x.round}.should == [36, 756]
        @pdf.map_to_absolute(to).map{|x| x.round}.should == [65, 756]
      end
      @pdf.cell(:content => "text", :borders => [:top])
    end

    it "should draw bottom border when requested" do
      @pdf.expects(:stroke_line).checking do |from, to|
        @pdf.map_to_absolute(from).map{|x| x.round}.should == [36, 732]
        @pdf.map_to_absolute(to).map{|x| x.round}.should == [65, 732]
      end
      @pdf.cell(:content => "text", :borders => [:bottom])
    end

    it "should draw left border when requested" do
      @pdf.expects(:stroke_line).checking do |from, to|
        @pdf.map_to_absolute(from).map{|x| x.round}.should == [36, 756]
        @pdf.map_to_absolute(to).map{|x| x.round}.should == [36, 732]
      end
      @pdf.cell(:content => "text", :borders => [:left])
    end

    it "should draw right border when requested" do
      @pdf.expects(:stroke_line).checking do |from, to|
        @pdf.map_to_absolute(from).map{|x| x.round}.should == [65, 756]
        @pdf.map_to_absolute(to).map{|x| x.round}.should == [65, 732]
      end
      @pdf.cell(:content => "text", :borders => [:right])
    end

    it "should draw borders at the same location when in or out of bbox" do
      @pdf.expects(:stroke_line).checking do |from, to|
        @pdf.map_to_absolute(from).map{|x| x.round}.should == [36, 756]
        @pdf.map_to_absolute(to).map{|x| x.round}.should == [65, 756]
      end
      @pdf.bounding_box([0, @pdf.cursor], :width => @pdf.bounds.width) do
        @pdf.cell(:content => "text", :borders => [:top])
      end
    end

    it "should set border color with :border_..._color" do
      @pdf.ignores(:stroke_color=).with("000000")
      @pdf.expects(:stroke_color=).with("ff0000")

      c = @pdf.cell(:content => "text", :border_top_color => "ff0000")
      c.border_top_color.should == "ff0000"
      c.border_colors[0].should == "ff0000"
    end

    it "should set border colors with :border_color" do
      @pdf.ignores(:stroke_color=).with("000000")
      @pdf.expects(:stroke_color=).with("ff0000")
      @pdf.expects(:stroke_color=).with("00ff00")
      @pdf.expects(:stroke_color=).with("0000ff")
      @pdf.expects(:stroke_color=).with("ff00ff")

      c = @pdf.cell(:content => "text",
        :border_color => %w[ff0000 00ff00 0000ff ff00ff])

      c.border_colors.should == %w[ff0000 00ff00 0000ff ff00ff]
    end

    it "border_..._width should return 0 if border not selected" do
      c = @pdf.cell(:content => "text", :borders => [:top])
      c.border_bottom_width.should == 0
    end

    it "should set border width with :border_..._width" do
      @pdf.ignores(:line_width=).with(1)
      @pdf.expects(:line_width=).with(2)

      c = @pdf.cell(:content => "text", :border_bottom_width => 2)
      c.border_bottom_width.should == 2
      c.border_widths[2].should == 2
    end

    it "should set border widths with :border_width" do
      @pdf.ignores(:line_width=).with(1)
      @pdf.expects(:line_width=).with(2)
      @pdf.expects(:line_width=).with(3)
      @pdf.expects(:line_width=).with(4)
      @pdf.expects(:line_width=).with(5)

      c = @pdf.cell(:content => "text",
        :border_width => [2, 3, 4, 5])
      c.border_widths.should == [2, 3, 4, 5]
    end

    it "should set default border lines to :solid" do
      c = @pdf.cell(:content => "text")
      c.border_top_line.should == :solid
      c.border_right_line.should == :solid
      c.border_bottom_line.should == :solid
      c.border_left_line.should == :solid
      c.border_lines.should == [:solid] * 4
    end

    it "should set border line with :border_..._line" do
      c = @pdf.cell(:content => "text", :border_bottom_line => :dotted)
      c.border_bottom_line.should == :dotted
      c.border_lines[2].should == :dotted
    end

    it "should set border lines with :border_lines" do
      c = @pdf.cell(:content => "text",
        :border_lines => [:solid, :dotted, :dashed, :solid])
      c.border_lines.should == [:solid, :dotted, :dashed, :solid]
    end
  end






  describe "Text cell attributes" do
    include CellHelpers

    it "should pass through text options like :align to Text::Box" do
      c = cell(:content => "text", :align => :right)

      box = Prawn::Text::Box.new("text", :document => @pdf)

      Prawn::Text::Box.expects(:new).checking do |text, options|
        text.should == "text"
        options[:align].should == :right
      end.at_least_once.returns(box)

      c.draw
    end

    it "should use font_style for Text::Box#style" do
      c = cell(:content => "text", :font_style => :bold)

      box = Prawn::Text::Box.new("text", :document => @pdf)

      Prawn::Text::Box.expects(:new).checking do |text, options|
        text.should == "text"
        options[:style].should == :bold
      end.at_least_once.returns(box)

      c.draw
    end

    it "supports variant styles of the current font" do
      @pdf.font "Courier"

      c = cell(:content => "text", :font_style => :bold)

      box = Prawn::Text::Box.new("text", :document => @pdf)
      Prawn::Text::Box.expects(:new).checking do |text, options|
        text.should == "text"
        options[:style].should == :bold
        @pdf.font.family.should == 'Courier'
      end.at_least_once.returns(box)

      c.draw
    end


    it "uses the style of the current font if none given" do
      @pdf.font "Courier", :style => :bold

      c = cell(:content => "text")

      box = Prawn::Text::Box.new("text", :document => @pdf)
      Prawn::Text::Box.expects(:new).checking do |text, options|
        text.should == "text"
        @pdf.font.family.should == 'Courier'
        @pdf.font.options[:style].should == :bold
      end.at_least_once.returns(box)

      c.draw
    end

    it "should allow inline formatting in cells" do
      c = cell(:content => "foo <b>bar</b> baz", :inline_format => true)

      box = Prawn::Text::Formatted::Box.new([], :document => @pdf)

      Prawn::Text::Formatted::Box.expects(:new).checking do |array, options|
        array[0][:text].should == "foo "
        array[0][:styles].should == []

        array[1][:text].should == "bar"
        array[1][:styles].should == [:bold]

        array[2][:text].should == " baz"
        array[2][:styles].should == []
      end.at_least_once.returns(box)

      c.draw
    end

  end

  describe "Font handling" do
    include CellHelpers

    it "should allow only :font_style to be specified, defaulting to the " +
       "document's font" do
      c = cell(:content => "text", :font_style => :bold)
      c.font.name.should == 'Helvetica-Bold'
    end

    it "should accept a font name for :font" do
      c = cell(:content => "text", :font => 'Helvetica-Bold')
      c.font.name.should == 'Helvetica-Bold'
    end

    it "should allow style to be changed after initialize" do
      c = cell(:content => "text")
      c.font_style = :bold
      c.font.name.should == 'Helvetica-Bold'
    end

    it "should default to the document's font, if none is specified" do
      c = cell(:content => "text")
      c.font.should == @pdf.font
    end

    it "should use the metrics of the selected font (even if it is a variant " +
       "of the document's font) to calculate width" do
      c = cell(:content => "text", :font_style => :bold)
      font = @pdf.find_font('Helvetica-Bold')
      c.content_width.should == font.compute_width_of("text")
    end

    it "should properly calculate inline-formatted text" do
      c = cell(:content => "<b>text</b>", :inline_format => true)
      font = @pdf.find_font('Helvetica-Bold')
      c.content_width.should == font.compute_width_of("text")
    end
  end
end

describe "Image cells" do
  before(:each) do
    create_pdf
  end

  describe "with default options" do
    before(:each) do
      @cell = Prawn::Table::Cell.make(@pdf,
        :image => "#{Prawn::DATADIR}/images/prawn.png")
    end

    it "should create a Cell::Image" do
      @cell.should be_a_kind_of(Prawn::Table::Cell::Image)
    end

    it "should pull the natural width and height from the image" do
      @cell.natural_content_width.should == 141
      @cell.natural_content_height.should == 142
    end
  end

  describe "hash syntax" do
    before(:each) do
      @table = @pdf.make_table([[{
        :image => "#{Prawn::DATADIR}/images/prawn.png",
        :scale => 2,
        :fit => [100, 200],
        :image_width => 123,
        :image_height => 456,
        :position => :center,
        :vposition => :center
      }]])
      @cell = @table.cells[0, 0]
    end


    it "should create a Cell::Image" do
      @cell.should be_a_kind_of(Prawn::Table::Cell::Image)
    end

    it "should pass through image options" do
      @pdf.expects(:embed_image).checking do |_, _, options|
        options[:scale].should == 2
        options[:fit].should == [100, 200]
        options[:width].should == 123
        options[:height].should == 456
        options[:position].should == :center
        options[:vposition].should == :center
      end

      @table.draw
    end
  end

end
