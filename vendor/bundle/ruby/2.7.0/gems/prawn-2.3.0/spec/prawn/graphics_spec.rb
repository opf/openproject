# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Graphics do
  let(:pdf) { create_pdf }

  describe 'When drawing a line' do
    it 'draws a line from (100,600) to (100,500)' do
      pdf.line([100, 600], [100, 500])

      line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)

      expect(line_drawing.points).to eq([[100, 600], [100, 500]])
    end

    it 'draws two lines at (100,600) to (100,500) and (75,100) to (50,125)' do
      pdf.line(100, 600, 100, 500)
      pdf.line(75, 100, 50, 125)

      line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)

      expect(line_drawing.points).to eq(
        [[100.0, 600.0], [100.0, 500.0], [75.0, 100.0], [50.0, 125.0]]
      )
    end

    it 'properlies set line width via line_width=' do
      pdf.line_width = 10
      line = PDF::Inspector::Graphics::Line.analyze(pdf.render)
      expect(line.widths.first).to eq(10)
    end

    it 'properlies set line width via line_width(width)' do
      pdf.line_width(10)
      line = PDF::Inspector::Graphics::Line.analyze(pdf.render)
      expect(line.widths.first).to eq(10)
    end

    it 'carries the current line width settings over to new pages' do
      pdf.line_width(10)
      pdf.start_new_page
      line = PDF::Inspector::Graphics::Line.analyze(pdf.render)
      expect(line.widths.length).to eq(2)
      expect(line.widths[1]).to eq(10)
    end

    describe '(Horizontally)' do
      it 'draws from [x1,pdf.y],[x2,pdf.y]' do
        pdf.horizontal_line(100, 150)
        line = PDF::Inspector::Graphics::Line.analyze(pdf.render)
        expect(line.points).to eq([
          [100.0 + pdf.bounds.absolute_left, pdf.y],
          [150.0 + pdf.bounds.absolute_left, pdf.y]
        ])
      end

      it 'draws a line from (200, 250) to (300, 250)' do
        pdf.horizontal_line(200, 300, at: 250)
        line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)
        expect(line_drawing.points).to eq([[200, 250], [300, 250]])
      end
    end

    describe '(Vertically)' do
      it 'draws a line from (350, 300) to (350, 400)' do
        pdf.vertical_line(300, 400, at: 350)
        line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)
        expect(line_drawing.points).to eq([[350, 300], [350, 400]])
      end

      it 'requires a y coordinate' do
        expect { pdf.vertical_line(400, 500) }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe 'When drawing a polygon' do
    it 'draws each line passed to polygon()' do
      pdf.polygon([100, 500], [100, 400], [200, 400])

      line_drawing = PDF::Inspector::Graphics::Line.analyze(pdf.render)
      expect(line_drawing.points)
        .to eq([[100, 500], [100, 400], [200, 400], [100, 500]])
    end
  end

  describe 'When drawing a rectangle' do
    it 'uses a point, width, and height for coords' do
      pdf.rectangle [200, 200], 50, 100

      rectangles = PDF::Inspector::Graphics::Rectangle.analyze(pdf.render)
        .rectangles
      # PDF uses bottom left corner
      expect(rectangles[0][:point]).to eq([200, 100])
      expect(rectangles[0][:width]).to eq(50)
      expect(rectangles[0][:height]).to eq(100)
    end
  end

  describe 'When drawing a curve' do
    it 'draws a bezier curve from 50,50 to 100,100' do
      pdf.move_to [50, 50]
      pdf.curve_to [100, 100], bounds: [[20, 90], [90, 70]]
      curve = PDF::Inspector::Graphics::Curve.analyze(pdf.render)
      expect(curve.coords)
        .to eq([50.0, 50.0, 20.0, 90.0, 90.0, 70.0, 100.0, 100.0])
    end

    it 'draws a bezier curve from 100,100 to 50,50' do
      pdf.curve [100, 100], [50, 50], bounds: [[20, 90], [90, 75]]
      curve = PDF::Inspector::Graphics::Curve.analyze(pdf.render)
      expect(curve.coords)
        .to eq([100.0, 100.0, 20.0, 90.0, 90.0, 75.0, 50.0, 50.0])
    end
  end

  describe 'When drawing a rounded rectangle' do
    before { pdf.rounded_rectangle([50, 550], 50, 100, 10) }

    let(:original_point) do
      curve = PDF::Inspector::Graphics::Curve.analyze(pdf.render)
      curve_points = curve.coords.each_slice(2).to_a
      curve_points.shift
    end
    let(:all_coords) do
      curve = PDF::Inspector::Graphics::Curve.analyze(pdf.render)
      curve_points = curve.coords.each_slice(2).to_a
      curve_points.shift
      curves = curve_points.each_slice(3).to_a
      line_points = PDF::Inspector::Graphics::Line.analyze(pdf.render).points
      line_points.shift
      line_points.zip(curves).flatten.each_slice(2).to_a.unshift original_point
    end

    it 'draws a rectangle by connecting lines with rounded bezier curves' do
      expect(all_coords).to eq(
        [
          [60.0, 550.0], [90.0, 550.0], [95.5228, 550.0], [100.0, 545.5228],
          [100.0, 540.0], [100.0, 460.0], [100.0, 454.4772], [95.5228, 450.0],
          [90.0, 450.0], [60.0, 450.0], [54.4772, 450.0], [50.0, 454.4772],
          [50.0, 460.0], [50.0, 540.0], [50.0, 545.5228], [54.4772, 550.0],
          [60.0, 550.0]
        ]
      )
    end

    it 'starts and end with the same point' do
      expect(original_point).to eq(all_coords.last)
    end
  end

  describe 'When drawing an ellipse' do
    let(:curve) do
      pdf.ellipse [100, 100], 25, 50
      PDF::Inspector::Graphics::Curve.analyze(pdf.render)
    end

    it 'uses a Bézier approximation' do
      expect(curve.coords).to eq([
        125.0, 100.0,

        125.0, 127.6142,
        113.8071, 150,
        100.0, 150.0,

        86.1929, 150.0,
        75.0, 127.6142,
        75.0, 100.0,

        75.0, 72.3858,
        86.1929, 50.0,
        100.0, 50.0,

        113.8071, 50.0,
        125.0, 72.3858,
        125.0, 100.0,

        100.0, 100.0
      ])
    end

    it 'moves the pointer to the center of the ellipse after drawing' do
      expect(curve.coords[-2..-1]).to eq([100, 100])
    end
  end

  describe 'When drawing a circle' do
    let(:curve) do
      pdf.circle [100, 100], 25
      pdf.ellipse [100, 100], 25, 25
      PDF::Inspector::Graphics::Curve.analyze(pdf.render)
    end

    it 'strokes the same path as the equivalent ellipse' do
      middle = curve.coords.length / 2
      expect(curve.coords[0...middle]).to eq(curve.coords[middle..-1])
    end
  end

  describe 'When filling' do
    it 'defaults to the f operator (nonzero winding number rule)' do
      allow(pdf.renderer).to receive(:add_content).with('f')
      pdf.fill
      expect(pdf.renderer).to have_received(:add_content).with('f')
    end

    it 'uses f* for :fill_rule => :even_odd' do
      allow(pdf.renderer).to receive(:add_content).with('f*')
      pdf.fill(fill_rule: :even_odd)
      expect(pdf.renderer).to have_received(:add_content).with('f*')
    end

    it 'uses b by default for fill_and_stroke (nonzero winding number)' do
      allow(pdf.renderer).to receive(:add_content).with('b')
      pdf.fill_and_stroke
      expect(pdf.renderer).to have_received(:add_content).with('b')
    end

    it 'uses b* for fill_and_stroke(:fill_rule => :even_odd)' do
      allow(pdf.renderer).to receive(:add_content).with('b*')
      pdf.fill_and_stroke(fill_rule: :even_odd)
      expect(pdf.renderer).to have_received(:add_content).with('b*')
    end
  end

  describe 'When setting colors' do
    it 'sets stroke colors' do
      pdf.stroke_color 'ffcccc'
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      # 100% red, 80% green, 80% blue
      expect(colors.stroke_color).to eq([1.0, 0.8, 0.8])
    end

    it 'sets fill colors' do
      pdf.fill_color 'ccff00'
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      # 80% red, 100% green, 0% blue
      expect(colors.fill_color).to eq([0.8, 1.0, 0])
    end

    it 'raises an error for a color with a leading #' do
      expect { pdf.fill_color '#ccff00' }.to raise_error(ArgumentError)
    end

    it 'raises an error for a color string that is not a hex' do
      expect { pdf.fill_color 'zcff00' }.to raise_error(ArgumentError)
    end

    it 'raises an error for a color string with invalid characters' do
      expect { pdf.fill_color 'f0f0f?' }.to raise_error(ArgumentError)
    end

    it 'resets the colors on each new page if they have been defined' do
      pdf.fill_color 'ccff00'

      pdf.start_new_page
      pdf.stroke_color 'ff00cc'

      pdf.start_new_page
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      expect(colors.fill_color_count).to eq(3)
      expect(colors.stroke_color_count).to eq(2)

      expect(colors.fill_color).to eq([0.8, 1.0, 0.0])
      expect(colors.stroke_color).to eq([1.0, 0.0, 0.8])
    end

    it 'sets the color space when setting colors on new pages to please fussy '\
      'readers' do
      pdf.stroke_color '000000'
      pdf.stroke { pdf.rectangle([10, 10], 10, 10) }
      pdf.start_new_page
      pdf.stroke_color '000000'
      pdf.stroke { pdf.rectangle([10, 10], 10, 10) }
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      expect(colors.stroke_color_space_count[:DeviceRGB]).to eq(2)
    end
  end

  describe 'Patterns' do
    describe 'linear gradients' do
      it 'creates a /Pattern resource' do
        pdf.fill_gradient(
          [0, pdf.bounds.height],
          [pdf.bounds.width, pdf.bounds.height],
          'FF0000', '0000FF'
        )

        grad = PDF::Inspector::Graphics::Pattern.analyze(pdf.render)
        pattern = grad.patterns.values.first

        expect(pattern).to_not be_nil
        expect(pattern[:Shading][:ShadingType]).to eq(2)
        expect(pattern[:Shading][:Coords]).to eq([0, 0, pdf.bounds.width, 0])
        expect(pattern[:Shading][:Function][:C0].zip([1, 0, 0]).all? do |x1, x2|
          (x1 - x2).abs < 0.01
        end).to eq true
        expect(pattern[:Shading][:Function][:C1].zip([0, 0, 1]).all? do |x1, x2|
          (x1 - x2).abs < 0.01
        end).to eq true
      end

      it 'creates a unique ID for each pattern resource' do
        pdf.fill_gradient(
          [256, 512],
          [356, 512],
          'ffffff', 'fe00ff'
        )
        pdf.fill_gradient(
          [256, 256],
          [356, 256],
          'ffffff', '0000ff'
        )

        str = pdf.render
        pattern_ids = str.scan(/SP\h{40}\s+scn/)
        expect(pattern_ids.uniq.length).to eq 2
      end

      it 'fill_gradient should set fill color to the pattern' do
        pdf.fill_gradient(
          [0, pdf.bounds.height],
          [pdf.bounds.width, pdf.bounds.height],
          'FF0000', '0000FF'
        )

        str = pdf.render
        expect(str).to match(%r{/Pattern\s+cs\s*/SP\h{40}\s+scn})
      end

      it 'stroke_gradient should set stroke color to the pattern' do
        pdf.stroke_gradient(
          [0, pdf.bounds.height],
          [pdf.bounds.width, pdf.bounds.height],
          'FF0000', '0000FF'
        )

        str = pdf.render
        expect(str).to match(%r{/Pattern\s+CS\s*/SP\h{40}\s+SCN})
      end

      it 'uses a stitching function to render a gradient with multiple stops' do
        pdf.fill_gradient(
          from: [0, pdf.bounds.height],
          to: [pdf.bounds.width, pdf.bounds.height],
          stops: { 0 => 'FF0000', 0.8 => '00FF00', 1 => '0000FF' }
        )

        grad = PDF::Inspector::Graphics::Pattern.analyze(pdf.render)
        pattern = grad.patterns.values.first

        expect(pattern).to_not be_nil

        stitching = pattern[:Shading][:Function]
        expect(stitching[:FunctionType]).to eq(3)
        expect(stitching[:Functions]).to be_an(Array)
        expect(stitching[:Functions].map { |f| f[:C0] })
          .to eq([[1, 0, 0], [0, 1, 0]])
        expect(stitching[:Functions].map { |f| f[:C1] })
          .to eq([[0, 1, 0], [0, 0, 1]])
        expect(stitching[:Bounds]).to eq([0.8])
        expect(stitching[:Encode]).to eq([0, 1, 0, 1])
      end

      it 'uses a stitching function to render a gradient with equally spaced '\
        'stops' do
        pdf.fill_gradient(
          from: [0, pdf.bounds.height],
          to: [pdf.bounds.width, pdf.bounds.height],
          stops: %w[FF0000 00FF00 0000FF]
        )

        grad = PDF::Inspector::Graphics::Pattern.analyze(pdf.render)
        pattern = grad.patterns.values.first

        expect(pattern).to_not be_nil

        stitching = pattern[:Shading][:Function]
        expect(stitching[:FunctionType]).to eq(3)
        expect(stitching[:Functions]).to be_an(Array)
        expect(stitching[:Functions].map { |f| f[:C0] })
          .to eq([[1, 0, 0], [0, 1, 0]])
        expect(stitching[:Functions].map { |f| f[:C1] })
          .to eq([[0, 1, 0], [0, 0, 1]])
        expect(stitching[:Bounds]).to eq([0.5])
      end
    end

    describe 'radial gradients' do
      it 'creates a /Pattern resource' do
        pdf.fill_gradient(
          [0, pdf.bounds.height], 10,
          [pdf.bounds.width, pdf.bounds.height], 20,
          'FF0000', '0000FF'
        )

        grad = PDF::Inspector::Graphics::Pattern.analyze(pdf.render)
        pattern = grad.patterns.values.first

        expect(pattern).to_not be_nil
        expect(pattern[:Shading][:ShadingType]).to eq(3)
        expect(pattern[:Shading][:Coords])
          .to eq([0, 0, 10, pdf.bounds.width, 0, 20])
        expect(pattern[:Shading][:Function][:C0].zip([1, 0, 0]).all? do |x1, x2|
          (x1 - x2).abs < 0.01
        end).to eq true
        expect(pattern[:Shading][:Function][:C1].zip([0, 0, 1]).all? do |x1, x2|
          (x1 - x2).abs < 0.01
        end).to eq true
      end

      it 'fill_gradient should set fill color to the pattern' do
        pdf.fill_gradient(
          [0, pdf.bounds.height], 10,
          [pdf.bounds.width, pdf.bounds.height], 20,
          'FF0000', '0000FF'
        )

        str = pdf.render
        expect(str).to match(%r{/Pattern\s+cs\s*/SP\h{40}\s+scn})
      end

      it 'stroke_gradient should set stroke color to the pattern' do
        pdf.stroke_gradient(
          [0, pdf.bounds.height], 10,
          [pdf.bounds.width, pdf.bounds.height], 20,
          'FF0000', '0000FF'
        )

        str = pdf.render
        expect(str).to match(%r{/Pattern\s+CS\s*/SP\h{40}\s+SCN})
      end
    end

    describe 'gradient transformations' do
      subject(:transformations) do
        pdf.scale 2 do
          pdf.translate 40, 40 do
            pdf.fill_gradient [0, 10], [15, 15], 'FF0000', '0000FF', opts
            pdf.fill_gradient [0, 10], 15, [15, 15], 25, 'FF0000', '0000FF',
              opts
          end
        end

        grad = PDF::Inspector::Graphics::Pattern.analyze(pdf.render)
        grad.patterns.values.map { |pattern| pattern[:Matrix] }.uniq
      end

      context 'when :apply_transformations is true' do
        let(:opts) { { apply_transformations: true } }

        it 'uses the transformation stack to translate user co-ordinates to '\
          'document co-ordinates required by /Pattern' do
          expect(transformations).to eq([[2, 0, 0, 2, 80, 100]])
        end
      end

      context 'when :apply_transformations is false' do
        let(:opts) { { apply_transformations: false } }

        it "doesn't transform the gradient" do
          expect(transformations).to eq([[1, 0, 0, 1, 0, 10]])
        end
      end

      context 'when :apply_transformations is unset' do
        let(:opts) { {} }

        it "doesn't transform the gradient and displays a warning" do
          allow(pdf).to receive(:warn).twice
          expect(transformations).to eq([[1, 0, 0, 1, 0, 10]])
          expect(pdf).to have_received(:warn).twice
        end
      end
    end
  end

  describe 'When using painting shortcuts' do
    it 'converts stroke_some_method(args) into some_method(args); stroke' do
      allow(pdf).to receive(:line_to).with([100, 100])
      allow(pdf).to receive(:stroke)

      pdf.stroke_line_to [100, 100]

      expect(pdf).to have_received(:line_to).with([100, 100])
      expect(pdf).to have_received(:stroke)
    end

    it 'converts fill_some_method(args) into some_method(args); fill' do
      allow(pdf).to receive(:line_to).with([100, 100])
      allow(pdf).to receive(:fill)

      pdf.fill_line_to [100, 100]

      expect(pdf).to have_received(:line_to).with([100, 100])
      expect(pdf).to have_received(:fill)
    end

    it 'does not break method_missing' do
      expect { pdf.i_have_a_pretty_girlfriend_named_jia }
        .to raise_error(NoMethodError)
    end
  end

  describe 'When using graphics states' do
    it 'adds the right content on save_graphics_state' do
      allow(pdf.renderer).to receive(:add_content).with('q')

      pdf.save_graphics_state

      expect(pdf.renderer).to have_received(:add_content).with('q')
    end

    it 'adds the right content on restore_graphics_state' do
      allow(pdf.renderer).to receive(:add_content).with('Q')

      pdf.restore_graphics_state

      expect(pdf.renderer).to have_received(:add_content).with('Q')
    end

    it 'saves and restore when save_graphics_state is used with a block' do
      allow(pdf.renderer).to receive(:add_content).with('q')
      allow(pdf).to receive(:foo)
      allow(pdf.renderer).to receive(:add_content).with('Q')

      pdf.save_graphics_state do
        pdf.foo
      end

      expect(pdf.renderer).to have_received(:add_content).with('q').ordered
      expect(pdf).to have_received(:foo).ordered
      expect(pdf.renderer).to have_received(:add_content).with('Q').ordered
    end

    it 'adds the previous color space when restoring to a graphic state with '\
      'different color space' do
      pdf.stroke_color '000000'
      pdf.save_graphics_state
      pdf.stroke_color 0, 0, 0, 0
      pdf.restore_graphics_state
      pdf.stroke_color 0, 0, 100, 0
      expect(pdf.graphic_state.color_space).to eq(stroke: :DeviceCMYK)
      colors = PDF::Inspector::Graphics::Color.analyze(pdf.render)
      expect(colors.color_space).to eq(:DeviceCMYK)
      expect(colors.stroke_color_space_count[:DeviceCMYK]).to eq(2)
    end

    it 'uses the correct dash setting after restoring and starting new page' do
      pdf.dash 5
      pdf.save_graphics_state
      pdf.dash 10
      expect(pdf.graphic_state.dash[:dash]).to eq(10)
      pdf.restore_graphics_state
      pdf.start_new_page
      expect(pdf.graphic_state.dash[:dash]).to eq(5)
    end

    it 'rounds dash values to four decimal places' do
      pdf.dash 5.12345
      expect(pdf.graphic_state.dash_setting).to eq('[5.1235 5.1235] 0.0 d')
    end

    it 'raises an error when dash is called w. a zero length or space' do
      expect { pdf.dash(0) }.to raise_error(ArgumentError)
      expect { pdf.dash([0]) }.to raise_error(ArgumentError)
      expect { pdf.dash([0, 0]) }.to raise_error(ArgumentError)
    end

    it 'raises an error when dash is called w. negative lengths' do
      expect { pdf.dash(-1) }.to raise_error(ArgumentError)
      expect { pdf.dash([1, -3]) }.to raise_error(ArgumentError)
    end

    it 'the current graphic state keeps track of previous unchanged settings' do
      pdf.stroke_color '000000'
      pdf.save_graphics_state
      pdf.dash 5
      pdf.save_graphics_state
      pdf.cap_style :round
      pdf.save_graphics_state
      pdf.fill_color 0, 0, 100, 0
      pdf.save_graphics_state

      expect(pdf.graphic_state.stroke_color).to eq('000000')
      expect(pdf.graphic_state.join_style).to eq(:miter)
      expect(pdf.graphic_state.fill_color).to eq([0, 0, 100, 0])
      expect(pdf.graphic_state.cap_style).to eq(:round)
      expect(pdf.graphic_state.color_space)
        .to eq(fill: :DeviceCMYK, stroke: :DeviceRGB)
      expect(pdf.graphic_state.dash).to eq(space: 5, phase: 0, dash: 5)
      expect(pdf.graphic_state.line_width).to eq(1)
    end

    it "doesn't add extra graphic space closings when rendering multiple " \
      'times' do
      pdf.render
      state = PDF::Inspector::Graphics::State.analyze(pdf.render)
      expect(state.save_graphics_state_count).to eq(1)
      expect(state.restore_graphics_state_count).to eq(1)
    end

    it 'adds extra graphic state enclosings when content is added on multiple '\
      'renderings' do
      pdf.render
      pdf.text 'Adding a bit more content'
      state = PDF::Inspector::Graphics::State.analyze(pdf.render)
      expect(state.save_graphics_state_count).to eq(2)
      expect(state.restore_graphics_state_count).to eq(2)
    end

    it 'adds extra graphic state enclosings when new settings are applied on '\
      'multiple renderings' do
      pdf.render
      pdf.stroke_color 0, 0, 0, 0
      state = PDF::Inspector::Graphics::State.analyze(pdf.render)
      expect(state.save_graphics_state_count).to eq(2)
      expect(state.restore_graphics_state_count).to eq(2)
    end

    it 'raise_errors error if closing an empty graphic stack' do
      expect do
        pdf.render
        pdf.restore_graphics_state
      end.to raise_error(PDF::Core::Errors::EmptyGraphicStateStack)
    end

    it 'copies mutable attributes when passing a previous_state to '\
      'the initializer' do
      new_state = PDF::Core::GraphicState.new(pdf.graphic_state)

      %i[color_space dash fill_color stroke_color].each do |attr|
        expect(new_state.send(attr)).to eq(pdf.graphic_state.send(attr))
        expect(new_state.send(attr)).to_not equal(pdf.graphic_state.send(attr))
      end
    end

    it 'copies mutable attributes when duping' do
      new_state = pdf.graphic_state.dup

      %i[color_space dash fill_color stroke_color].each do |attr|
        expect(new_state.send(attr)).to eq(pdf.graphic_state.send(attr))
        expect(new_state.send(attr)).to_not equal(pdf.graphic_state.send(attr))
      end
    end
  end

  describe 'When using transformation matrix' do
    # Note: The (approximate) number of significant decimal digits of precision
    # in fractional part is 5 (PDF Reference, Third Edition, p. 706)

    it 'sends the right content on transformation_matrix' do
      allow(pdf.renderer).to receive(:add_content)
        .with('1.0 0.0 0.12346 -1.0 5.5 20.0 cm')
      pdf.transformation_matrix 1, 0, 0.123456789, -1.0, 5.5, 20
      expect(pdf.renderer).to have_received(:add_content)
        .with('1.0 0.0 0.12346 -1.0 5.5 20.0 cm')
    end

    it 'uses fixed digits with very small number' do
      values = Array.new(6, 0.000000000001)
      string = Array.new(6, '0.0').join ' '
      allow(pdf.renderer).to receive(:add_content).with("#{string} cm")
      pdf.transformation_matrix(*values)
      expect(pdf.renderer).to have_received(:add_content).with("#{string} cm")
    end

    it 'is received by the inspector' do
      pdf.transformation_matrix 1, 0, 0, -1, 5.5, 20
      matrices = PDF::Inspector::Graphics::Matrix.analyze(pdf.render)
      expect(matrices.matrices).to eq([[1, 0, 0, -1, 5.5, 20]])
    end

    it 'saves the graphics state inside the given block' do
      values = Array.new(6, 0.000000000001)
      string = Array.new(6, '0.0').join ' '

      allow(pdf).to receive(:save_graphics_state).with(no_args)
      allow(pdf.renderer).to receive(:add_content).with(any_args).twice
      allow(pdf.renderer).to receive(:add_content).with("#{string} cm")
      allow(pdf).to receive(:do_something)
      allow(pdf).to receive(:restore_graphics_state).with(no_args)

      pdf.transformation_matrix(*values) do
        pdf.do_something
      end

      expect(pdf).to have_received(:save_graphics_state).with(no_args).ordered
      expect(pdf.renderer).to have_received(:add_content).with("#{string} cm")
        .ordered
      expect(pdf).to have_received(:do_something).ordered
      expect(pdf).to have_received(:restore_graphics_state).with(no_args)
        .ordered
    end
  end

  describe 'When using transformations shortcuts' do
    let(:x) { 12 }
    let(:y) { 54.32 }
    let(:angle) { 12.32 }
    let(:cos) { Math.cos(angle * Math::PI / 180) }
    let(:sin) { Math.sin(angle * Math::PI / 180) }
    let(:factor) { 0.12 }

    describe '#rotate' do
      it 'rotates' do
        allow(pdf).to receive(:transformation_matrix)
          .with(cos, sin, -sin, cos, 0, 0)
        pdf.rotate(angle)
        expect(pdf).to have_received(:transformation_matrix)
          .with(cos, sin, -sin, cos, 0, 0)
      end
    end

    describe '#rotate with :origin option' do
      it 'rotates around the origin' do
        x_prime = x * cos - y * sin
        y_prime = x * sin + y * cos

        pdf.rotate(angle, origin: [x, y]) { pdf.text('hello world') }

        matrices = PDF::Inspector::Graphics::Matrix.analyze(pdf.render)
        expect(matrices.matrices[0]).to eq([
          1, 0, 0, 1,
          reduce_precision(x - x_prime),
          reduce_precision(y - y_prime)
        ])
        expect(matrices.matrices[1]).to eq([
          reduce_precision(cos),
          reduce_precision(sin),
          reduce_precision(-sin),
          reduce_precision(cos),
          0, 0
        ])
      end

      it 'rotates around the origin in a document with a margin' do
        pdf = Prawn::Document.new

        pdf.rotate(angle, origin: [x, y]) { pdf.text('hello world') }

        x_ = x + pdf.bounds.absolute_left
        y_ = y + pdf.bounds.absolute_bottom
        x_prime = x_ * cos - y_ * sin
        y_prime = x_ * sin + y_ * cos

        matrices = PDF::Inspector::Graphics::Matrix.analyze(pdf.render)
        expect(matrices.matrices[0]).to eq([
          1, 0, 0, 1,
          reduce_precision(x_ - x_prime),
          reduce_precision(y_ - y_prime)
        ])
        expect(matrices.matrices[1]).to eq([
          reduce_precision(cos),
          reduce_precision(sin),
          reduce_precision(-sin),
          reduce_precision(cos),
          0, 0
        ])
      end

      it 'raise_errors BlockRequired if no block is given' do
        expect do
          pdf.rotate(angle, origin: [x, y])
        end.to raise_error(Prawn::Errors::BlockRequired)
      end
    end

    describe '#translate' do
      it 'translates' do
        x = 12
        y = 54.32
        allow(pdf).to receive(:transformation_matrix).with(1, 0, 0, 1, x, y)
        pdf.translate(x, y)
        expect(pdf).to have_received(:transformation_matrix)
          .with(1, 0, 0, 1, x, y)
      end
    end

    describe '#scale' do
      it 'scales' do
        allow(pdf).to receive(:transformation_matrix)
          .with(factor, 0, 0, factor, 0, 0)
        pdf.scale(factor)
        expect(pdf).to have_received(:transformation_matrix)
          .with(factor, 0, 0, factor, 0, 0)
      end
    end

    describe '#scale with :origin option' do
      it 'scales from the origin' do
        x_prime = factor * x
        y_prime = factor * y

        pdf.scale(factor, origin: [x, y]) { pdf.text('hello world') }

        matrices = PDF::Inspector::Graphics::Matrix.analyze(pdf.render)
        expect(matrices.matrices[0]).to eq([
          1, 0, 0, 1,
          reduce_precision(x - x_prime),
          reduce_precision(y - y_prime)
        ])
        expect(matrices.matrices[1]).to eq([factor, 0, 0, factor, 0, 0])
      end

      it 'scales from the origin in a document with a margin' do
        pdf = Prawn::Document.new
        x_ = x + pdf.bounds.absolute_left
        y_ = y + pdf.bounds.absolute_bottom
        x_prime = factor * x_
        y_prime = factor * y_

        pdf.scale(factor, origin: [x, y]) { pdf.text('hello world') }

        matrices = PDF::Inspector::Graphics::Matrix.analyze(pdf.render)
        expect(matrices.matrices[0]).to eq([
          1, 0, 0, 1,
          reduce_precision(x_ - x_prime),
          reduce_precision(y_ - y_prime)
        ])
        expect(matrices.matrices[1]).to eq([factor, 0, 0, factor, 0, 0])
      end

      it 'raise_errors BlockRequired if no block is given' do
        expect do
          pdf.scale(factor, origin: [x, y])
        end.to raise_error(Prawn::Errors::BlockRequired)
      end
    end
  end

  def reduce_precision(float)
    float.round(5)
  end
end
