# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Repeater do
  it 'creates a stamp and increments Prawn::Repeater.count on initialize' do
    orig_count = described_class.count

    doc = sample_document
    allow(doc).to receive(:create_stamp).with("prawn_repeater(#{orig_count})")

    repeater(doc, :all) { :do_nothing }

    expect(doc).to have_received(:create_stamp)
      .with("prawn_repeater(#{orig_count})")

    expect(described_class.count).to eq(orig_count + 1)
  end

  it 'must provide an :all filter' do
    doc = sample_document
    r = repeater(doc, :all) { :do_nothing }

    expect((1..doc.page_count).all? { |i| r.match?(i) }).to eq true
  end

  it 'must provide an :odd filter' do
    doc = sample_document
    r = repeater(doc, :odd) { :do_nothing }

    odd, even = (1..doc.page_count).partition(&:odd?)

    expect(odd.all? { |i| r.match?(i) }).to eq true
    expect(even.any? { |i| r.match?(i) }).to eq false
  end

  it 'must be able to filter by an array of page numbers' do
    doc = sample_document
    r = repeater(doc, [1, 2, 7]) { :do_nothing }

    expect((1..10).select { |i| r.match?(i) }).to eq([1, 2, 7])
  end

  it 'must be able to filter by a range of page numbers' do
    doc = sample_document
    r = repeater(doc, 2..4) { :do_nothing }

    expect((1..10).select { |i| r.match?(i) }).to eq([2, 3, 4])
  end

  it 'must be able to filter by an arbitrary proc' do
    doc = sample_document
    r = repeater(doc, ->(x) { x == 1 || x % 3 == 0 })

    expect((1..10).select { |i| r.match?(i) }).to eq([1, 3, 6, 9])
  end

  it 'must try to run a stamp if the page number matches' do
    doc = sample_document
    allow(doc).to receive(:stamp)

    repeater(doc, :odd).run(3)
    expect(doc).to have_received(:stamp)
  end

  it 'must not try to run a stamp unless the page number matches' do
    doc = sample_document

    allow(doc).to receive(:stamp)
    repeater(doc, :odd).run(2)
    expect(doc).to_not have_received(:stamp)
  end

  it 'must not try to run a stamp if dynamic is selected' do
    doc = sample_document

    allow(doc).to receive(:stamp)
    (1..10).each { |p| repeater(doc, :all, true) { :do_nothing }.run(p) }
    expect(doc).to_not have_received(:stamp)
  end

  it 'must try to run a block if the page number matches' do
    doc = sample_document

    allow(doc).to receive(:draw_text)
    (1..10).each do |p|
      repeater(doc, [1, 2], true) { doc.draw_text 'foo' }.run(p)
    end
    expect(doc).to have_received(:draw_text).twice
  end

  it 'must not try to run a block unless the page number matches' do
    doc = sample_document

    allow(doc).to receive(:draw_text)
    repeater(doc, :odd, true) { doc.draw_text 'foo' }.run(2)
    expect(doc).to_not have_received(:draw_text)
  end

  it 'must treat any block as a closure' do
    doc = sample_document

    page = 'Page' # ensure access to ivars
    doc.repeat(:all, dynamic: true) do
      doc.draw_text "#{page} #{doc.page_number}", at: [500, 0]
    end

    text = PDF::Inspector::Text.analyze(doc.render)
    expect(text.strings).to eq((1..10).to_a.map { |p| "Page #{p}" })
  end

  it 'must treat any block as a closure (Document.new instance_eval form)' do
    doc = Prawn::Document.new(skip_page_creation: true) do
      10.times { start_new_page }

      page = 'Page'
      repeat(:all, dynamic: true) do
        # ensure self is accessible here
        draw_text "#{page} #{page_number}", at: [500, 0]
      end
    end

    text = PDF::Inspector::Text.analyze(doc.render)
    expect(text.strings).to eq((1..10).to_a.map { |p| "Page #{p}" })
  end

  def sample_document
    doc = Prawn::Document.new(skip_page_creation: true)
    10.times { |_e| doc.start_new_page }
    doc
  end

  def repeater(*args, &block)
    Prawn::Repeater.new(*args, &block)
  end

  describe 'graphic state' do
    let(:pdf) { create_pdf }

    it 'does not alter the graphic state stack color space' do
      starting_color_space = pdf.state.page.graphic_state.color_space.dup
      pdf.repeat :all do
        pdf.text 'Testing', size: 24, style: :bold
      end
      expect(pdf.state.page.graphic_state.color_space)
        .to eq(starting_color_space)
    end

    context 'with dynamic repeaters' do
      it 'preserves the graphic state at creation time' do
        pdf.repeat :all, dynamic: true do
          pdf.text "fill_color: #{pdf.graphic_state.fill_color}"
          pdf.text "cap_style: #{pdf.graphic_state.cap_style}"
        end
        pdf.fill_color '666666'
        pdf.cap_style :round
        text = PDF::Inspector::Text.analyze(pdf.render)
        expect(text.strings.include?('fill_color: 666666')).to eq(false)
        expect(text.strings.include?('fill_color: 000000')).to eq(true)
        expect(text.strings.include?('cap_style: round')).to eq(false)
        expect(text.strings.include?('cap_style: butt')).to eq(true)
      end
    end
  end
end
