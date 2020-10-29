# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Document::BoundingBox do
  let(:pdf) { create_pdf }
  let(:x) { 100 }
  let(:y) { 125 }
  let(:width) { 50 }
  let(:height) { 75 }
  let(:box) do
    described_class.new(
      nil,
      nil,
      [x, y],
      width: width,
      height: height
    )
  end

  it 'has an anchor at (x, y - height)' do
    expect(box.anchor).to eq([x, y - height])
  end

  it 'has a left boundary of 0' do
    expect(box.left).to eq(0)
  end

  it 'has a right boundary equal to the width' do
    expect(box.right).to eq(width)
  end

  it 'has a top boundary of height' do
    expect(box.top).to eq(height)
  end

  it 'has a bottom boundary of 0' do
    expect(box.bottom).to eq(0)
  end

  it 'has a top-left of [0,height]' do
    expect(box.top_left).to eq([0, height])
  end

  it 'has a top-right of [width,height]' do
    expect(box.top_right).to eq([width, height])
  end

  it 'has a bottom-left of [0,0]' do
    expect(box.bottom_left).to eq([0, 0])
  end

  it 'has a bottom-right of [width,0]' do
    expect(box.bottom_right).to eq([width, 0])
  end

  it 'has an absolute left boundary of x' do
    expect(box.absolute_left).to eq(x)
  end

  it 'has an absolute right boundary of x + width' do
    expect(box.absolute_right).to eq(x + width)
  end

  it 'has an absolute top boundary of y' do
    expect(box.absolute_top).to eq(y)
  end

  it 'has an absolute bottom boundary of y - height' do
    expect(box.absolute_bottom).to eq(y - height)
  end

  it 'has an absolute bottom-left of [x,y-height]' do
    expect(box.absolute_bottom_left).to eq([x, y - height])
  end

  it 'has an absolute bottom-right of [x+width,y-height]' do
    expect(box.absolute_bottom_right).to eq([x + width, y - height])
  end

  it 'has an absolute top-left of [x,y]' do
    expect(box.absolute_top_left).to eq([x, y])
  end

  it 'has an absolute top-right of [x+width,y]' do
    expect(box.absolute_top_right).to eq([x + width, y])
  end

  it 'requires width to be set' do
    expect do
      described_class.new(nil, nil, [100, 100])
    end.to raise_error(ArgumentError)
  end

  it 'raise_errors an ArgumentError if a block is not passed' do
    pdf = Prawn::Document.new
    expect do
      pdf.bounding_box([0, 0], width: 200)
    end.to raise_error(ArgumentError)
  end

  describe 'drawing' do
    it 'does not stomp on the arguments to bounding_box' do
      pdf = Prawn::Document.new
      x = [100, 500]
      pdf.bounding_box x, width: 100 do
        pdf.text 'bork-bork-bork'
      end
      expect(x).to eq([100, 500])
    end

    it 'restores Document#bounds to the correct margin box on exit' do
      pdf = Prawn::Document.new(margin: 200)

      # add a multi-page bounding box
      pdf.bounding_box([100, pdf.bounds.top], width: 400) do
        pdf.text "The rain in spain falls mainly in the plains.\n" * 30
      end

      pdf.start_new_page(margin: 0)

      x_min, y_min, x_max, y_max = pdf.page.dimensions

      expect(pdf.bounds.absolute_top_left).to eq([x_min, y_max])
      expect(pdf.bounds.absolute_bottom_right).to eq([x_max, y_min])
    end

    it 'restores the parent bounding box when calls are nested' do
      pdf.bounding_box [100, 500], width: 300, height: 300 do
        expect(pdf.bounds.absolute_top)
          .to eq(500 + pdf.margin_box.absolute_bottom)
        expect(pdf.bounds.absolute_left)
          .to eq(100 + pdf.margin_box.absolute_left)

        parent_box = pdf.bounds

        pdf.bounding_box [50, 200], width: 100, height: 100 do
          expect(pdf.bounds.absolute_top)
            .to eq(200 + parent_box.absolute_bottom)
          expect(pdf.bounds.absolute_left).to eq(50 + parent_box.absolute_left)
        end

        expect(pdf.bounds.absolute_top)
          .to eq(500 + pdf.margin_box.absolute_bottom)
        expect(pdf.bounds.absolute_left)
          .to eq(100 + pdf.margin_box.absolute_left)
      end
    end

    it 'calculates a height if none is specified' do
      pdf.bounding_box([100, 500], width: 100) do
        pdf.text 'The rain in Spain falls mainly on the plains.'
      end

      expect(pdf.y).to be_within(0.001).of(458.384)
    end

    it 'keeps track of the max height the box was stretched to' do
      box = pdf.bounding_box(pdf.bounds.top_left, width: 100) do
        pdf.move_down 100
        pdf.move_up 15
      end

      expect(box.height).to eq(100)
    end

    it 'advances the y-position by bbox.height by default' do
      orig_y = pdf.y
      pdf.bounding_box [0, pdf.cursor], width: pdf.bounds.width, height: 30 do
        pdf.text 'hello'
      end
      expect(pdf.y).to be_within(0.001).of(orig_y - 30)
    end

    it 'does not advance y-position if passed :hold_position => true' do
      orig_y = pdf.y
      pdf.bounding_box(
        [0, pdf.cursor],
        width: pdf.bounds.width,
        hold_position: true
      ) do
        pdf.text 'hello'
      end
      # y only advances by height of one line ("hello")
      expect(pdf.y).to be_within(0.001).of(orig_y - pdf.height_of('hello'))
    end

    it 'does not advance y-position of a stretchy bbox if it would stretch '\
       'the bbox further' do
      bottom = pdf.y = pdf.margin_box.absolute_bottom
      pdf.bounding_box [0, pdf.margin_box.top], width: pdf.bounds.width do
        pdf.y = bottom
        pdf.text 'hello' # starts a new page
      end
      expect(pdf.page_count).to eq(2)

      # Restoring the position (to the absolute bottom) would stretch the bbox
      # to the bottom of the page, which we don't want. This should be
      # equivalent to a bbox with :hold_position => true, where we only advance
      # by the amount that was actually drawn.
      expect(pdf.y).to be_within(0.001).of(
        pdf.margin_box.absolute_top - pdf.height_of('hello')
      )
    end
  end

  describe 'Indentation' do
    it 'temporarilies shift the x coordinate and width' do
      pdf.bounding_box([100, 100], width: 200) do
        pdf.indent(20) do
          expect(pdf.bounds.absolute_left).to eq(120)
          expect(pdf.bounds.width).to eq(180)
        end
      end
    end

    it 'restores the x coordinate and width after block exits' do
      pdf.bounding_box([100, 100], width: 200) do
        pdf.indent(20) do
          # no-op
        end
        expect(pdf.bounds.absolute_left).to eq(100)
        expect(pdf.bounds.width).to eq(200)
      end
    end

    it 'restores the x coordinate and width on error' do
      pdf.bounding_box([100, 100], width: 200) do
        pdf.indent(20) { raise }
      rescue StandardError
        expect(pdf.bounds.absolute_left).to eq(100)
        expect(pdf.bounds.width).to eq(200)
      end
    end

    it 'maintains left indentation across a page break' do
      original_left = pdf.bounds.absolute_left

      pdf.indent(20) do
        expect(pdf.bounds.absolute_left).to eq(original_left + 20)
        pdf.start_new_page
        expect(pdf.bounds.absolute_left).to eq(original_left + 20)
      end

      expect(pdf.bounds.absolute_left).to eq(original_left)
    end

    it 'maintains right indentation across a page break' do
      original_width = pdf.bounds.width

      pdf.indent(0, 20) do
        expect(pdf.bounds.width).to eq(original_width - 20)
        pdf.start_new_page
        expect(pdf.bounds.width).to eq(original_width - 20)
      end

      expect(pdf.bounds.width).to eq(original_width)
    end

    it 'optionally allows adjustment of the right bound as well' do
      pdf.bounding_box([100, 100], width: 200) do
        pdf.indent(20, 30) do
          expect(pdf.bounds.absolute_left).to eq(120)
          expect(pdf.bounds.width).to eq(150)
        end
        expect(pdf.bounds.absolute_left).to eq(100)
        expect(pdf.bounds.width).to eq(200)
      end
    end

    describe 'in a ColumnBox' do
      it 'subtracts the given indentation from the available width' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          height: 200,
          columns: 2,
          spacer: 20
        ) do
          width = pdf.bounds.width
          pdf.indent(20) do
            expect(pdf.bounds.width).to be_within(0.01).of(width - 20)
          end
        end
      end

      it 'subtracts right padding from the available width' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          height: 200,
          columns: 2,
          spacer: 20
        ) do
          width = pdf.bounds.width
          pdf.indent(20, 30) do
            expect(pdf.bounds.width).to be_within(0.01).of(width - 50)
          end
        end
      end

      it 'maintains the same left indentation across column breaks' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          columns: 3,
          spacer: 15
        ) do
          3.times do |_column|
            x = pdf.bounds.left_side
            pdf.indent(20) do
              expect(pdf.bounds.left_side).to eq(x + 20)
            end
            pdf.bounds.move_past_bottom
          end
        end
      end

      it 'does not change the right margin if only left indentation is '\
        'requested' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          columns: 3,
          spacer: 15
        ) do
          3.times do |_column|
            x = pdf.bounds.right_side
            pdf.indent(20) do
              expect(pdf.bounds.right_side).to eq(x)
            end
            pdf.bounds.move_past_bottom
          end
        end
      end

      it 'maintains the same right indentation across columns' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          columns: 3,
          spacer: 15
        ) do
          3.times do |_column|
            x = pdf.bounds.right_side
            pdf.indent(20, 10) do
              expect(pdf.bounds.right_side).to eq(x - 10)
            end
            pdf.bounds.move_past_bottom
          end
        end
      end

      it 'keeps the right indentation after nesting indents' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          columns: 3,
          spacer: 15
        ) do
          3.times do |_column|
            # I am giving a right indent of 10...
            pdf.indent(20, 10) do
              x = pdf.bounds.right_side
              # ...and no right indent here...
              pdf.indent(20) do
                # right indent is inherited from the parent!
                expect(pdf.bounds.right_side).to eq(x)
              end
            end
            pdf.bounds.move_past_bottom
          end
        end
      end

      it 'reverts the right indentation if negative indent is given in '\
        'nested indent' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          columns: 3,
          spacer: 15
        ) do
          3.times do |_column|
            x = pdf.bounds.right_side
            pdf.indent(20, 10) do
              # requesting a negative right-indent of equivalent size...
              pdf.indent(20, -10) do
                # ...resets the right margin to that of the column!
                expect(pdf.bounds.right_side).to eq(x)
              end
            end
            pdf.bounds.move_past_bottom
          end
        end
      end

      it 'reduces the available column width by the sum of ' \
        'all nested indents' do
        pdf.column_box(
          [0, pdf.cursor],
          width: pdf.bounds.width,
          columns: 3,
          spacer: 15
        ) do
          3.times do |_column|
            w = pdf.bounds.width
            pdf.indent(20, 10) do
              pdf.indent(20, 10) do
                expect(pdf.bounds.width).to eq(w - 60)
              end
            end
            pdf.bounds.move_past_bottom
          end
        end
      end
    end
  end

  describe 'A canvas' do
    it 'uses whatever the last set y position is' do
      pdf.canvas do
        pdf.bounding_box([100, 500], width: 200) { pdf.move_down 50 }
      end
      expect(pdf.y).to eq(450)
    end

    it 'restores the original ypos after execution', issue: 523 do
      doc = Prawn::Document.new(skip_page_creation: true)
      doc.start_new_page

      original_ypos = doc.y

      doc.canvas {}

      expect(doc.y).to eq(original_ypos)
    end
  end

  describe 'Deep-copying' do
    it 'creates a new object that does not copy @document' do
      Prawn::Document.new do |pdf|
        orig = pdf.bounds
        copy = orig.deep_copy

        expect(copy).to_not eq(pdf.bounds)
        expect(copy.document).to be_nil
      end
    end

    it 'deep-copies parent bounds' do
      Prawn::Document.new do |pdf|
        outside = pdf.bounds
        pdf.bounding_box [100, 100], width: 100 do
          copy = pdf.bounds.deep_copy

          # the parent bounds should have the same parameters
          expect(copy.parent.width).to eq(outside.width)
          expect(copy.parent.height).to eq(outside.height)

          # but should not be the same object
          expect(copy.parent).to_not eq(outside)
        end
      end
    end
  end

  describe 'Prawn::Document#reference_bounds' do
    it 'returns self for non-stretchy bounds' do
      pdf.bounding_box([0, pdf.cursor], width: 100, height: 100) do
        expect(pdf.reference_bounds).to eq(pdf.bounds)
      end
    end

    it 'returns the parent bounds if in a stretchy box' do
      pdf.bounding_box([0, pdf.cursor], width: 100, height: 100) do
        correct_bounds = pdf.bounds
        pdf.bounding_box([0, pdf.cursor], width: 100) do
          expect(pdf.reference_bounds).to eq(correct_bounds)
        end
      end
    end

    it 'finds the non-stretchy box through 2 levels' do
      pdf.bounding_box([0, pdf.cursor], width: 100, height: 100) do
        correct_bounds = pdf.bounds
        pdf.bounding_box([0, pdf.cursor], width: 100) do
          pdf.bounding_box([0, pdf.cursor], width: 100) do
            expect(pdf.reference_bounds).to eq(correct_bounds)
          end
        end
      end
    end

    it "returns the margin box if there's no explicit bbox" do
      expect(pdf.reference_bounds).to eq(pdf.margin_box)

      pdf.bounding_box([0, pdf.cursor], width: 100) do
        expect(pdf.reference_bounds).to eq(pdf.margin_box)
      end
    end

    it "returns the canvas box if we're in a canvas" do
      pdf.canvas do
        canvas_box = pdf.bounds

        expect(pdf.reference_bounds).to eq(canvas_box)

        pdf.bounding_box([0, pdf.cursor], width: 100) do
          expect(pdf.reference_bounds).to eq(canvas_box)
        end
      end
    end
  end

  describe '#move_past_bottom' do
    it 'ordinarilies start a new page' do
      pdf.bounds.move_past_bottom
      pdf.text 'Foo'

      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
      expect(pages[0][:strings]).to eq([])
      expect(pages[1][:strings]).to eq(['Foo'])
    end

    it 'moves to the top of the next page if it exists already' do
      # save away the y-position at the top of a page
      top_y = pdf.y

      # create a blank page but go to the page before it
      pdf.start_new_page
      pdf.go_to_page 1
      pdf.text 'Foo'

      pdf.bounds.move_past_bottom
      expect(pdf.y).to be_within(0.001).of(top_y)
      pdf.text 'Bar'

      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
      expect(pages[0][:strings]).to eq(['Foo'])
      expect(pages[1][:strings]).to eq(['Bar'])
    end
  end
end
