# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Prawn::Document do
  let(:pdf) { create_pdf }

  describe '.new' do
    it 'does not modify its argument' do
      options = { page_layout: :landscape }
      described_class.new(options)
      expect(options).to eq(page_layout: :landscape)
    end
  end

  describe 'The cursor' do
    it 'equals pdf.y - bounds.absolute_bottom' do
      pdf = described_class.new
      expect(pdf.cursor).to eq(pdf.bounds.top)

      pdf.y = 300
      expect(pdf.cursor).to eq(pdf.y - pdf.bounds.absolute_bottom)
    end

    it 'is able to move relative to the bottom margin' do
      pdf = described_class.new
      pdf.move_cursor_to(10)

      expect(pdf.cursor).to eq(10)
      expect(pdf.y).to eq(pdf.cursor + pdf.bounds.absolute_bottom)
    end
  end

  describe 'when generating a document with a custom text formatter' do
    it 'uses the provided text formatter' do
      text_formatter = Class.new do
        def self.format(string)
          [
            {
              text: string.gsub('Dr. Who?', "Just 'The Doctor'."),
              styles: [],
              color: nil,
              link: nil,
              anchor: nil,
              local: nil,
              font: nil,
              size: nil,
              character_spacing: nil
            }
          ]
        end
      end
      pdf = described_class.new text_formatter: text_formatter
      pdf.text 'Dr. Who?', inline_format: true
      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq("Just 'The Doctor'.")
    end
  end

  describe 'when generating a document from a subclass' do
    it 'is an instance of the subclass' do
      custom_document = Class.new(described_class)
      custom_document.generate(Tempfile.new('generate_test').path) do |e|
        expect(e.class).to eq(custom_document)
        expect(e).to be_a_kind_of(described_class)
      end
    end

    it 'retains any extensions found on Prawn::Document' do
      mod1 = Module.new { attr_reader :test_extensions1 }
      mod2 = Module.new { attr_reader :test_extensions2 }

      described_class.extensions << mod1 << mod2

      custom_document = Class.new(described_class)
      expect(custom_document.extensions).to eq([mod1, mod2])

      # remove the extensions we added to prawn document
      described_class.extensions.delete(mod1)
      described_class.extensions.delete(mod2)

      expect(described_class.new.respond_to?(:test_extensions1)).to eq false
      expect(described_class.new.respond_to?(:test_extensions2)).to eq false

      # verify these still exist on custom class
      expect(custom_document.extensions).to eq([mod1, mod2])

      expect(custom_document.new.respond_to?(:test_extensions1)).to eq true
      expect(custom_document.new.respond_to?(:test_extensions2)).to eq true
    end
  end

  describe 'When creating multi-page documents' do
    it 'initializes with a single page' do
      page_counter = PDF::Inspector::Page.analyze(pdf.render)

      expect(page_counter.pages.size).to eq(1)
      expect(pdf.page_count).to eq(1)
    end

    it 'provides an accurate page_count' do
      3.times { pdf.start_new_page }
      page_counter = PDF::Inspector::Page.analyze(pdf.render)

      expect(page_counter.pages.size).to eq(4)
      expect(pdf.page_count).to eq(4)
    end
  end

  describe 'When beginning each new page' do
    describe 'Background image feature' do
      let(:filename) { "#{Prawn::DATADIR}/images/pigs.jpg" }
      let(:pdf) { described_class.new(background: filename) }

      it 'places a background image if it is in options block' do
        output = pdf.render
        images = PDF::Inspector::XObject.analyze(output)
        # there should be 2 images in the page resources
        expect(images.page_xobjects.first.size).to eq(1)
      end

      it 'places a background image interntally if it is in options block' do
        expect(pdf.instance_variable_defined?(:@background)).to eq(true)
        expect(pdf.instance_variable_get(:@background)).to eq(filename)
      end
    end
  end

  describe '#float' do
    it 'restores the original y-position' do
      orig_y = pdf.y
      pdf.float { pdf.text 'Foo' }
      expect(pdf.y).to eq(orig_y)
    end

    it 'teleports across pages if necessary' do
      pdf.float do
        pdf.text 'Foo'
        pdf.start_new_page
        pdf.text 'Bar'
      end
      pdf.text 'Baz'

      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(2)
      expect(pages[0][:strings]).to eq(%w[Foo Baz])
      expect(pages[1][:strings]).to eq(['Bar'])
    end
  end

  describe '#start_new_page' do
    it "doesn't modify the options hash" do
      expect do
        described_class.new.start_new_page({ margin: 0 }.freeze)
      end.to_not raise_error
    end

    it 'sets individual page margins' do
      doc = described_class.new
      doc.start_new_page(top_margin: 42)
      expect(doc.page.margins[:top]).to eq(42)
    end
  end

  describe '#delete_page(index)' do
    before do
      pdf.text 'Page one'
      pdf.start_new_page
      pdf.text 'Page two'
      pdf.start_new_page
      pdf.text 'Page three'
    end

    it 'destroy a specific page of the document' do
      pdf.delete_page(1)
      expect(pdf.page_number).to eq(2)
      text_analysis = PDF::Inspector::Text.analyze(pdf.render)
      expect(text_analysis.strings).to eq(['Page one', 'Page three'])
    end

    it 'destroy the last page of the document' do
      pdf.delete_page(-1)
      expect(pdf.page_number).to eq(2)
      text_analysis = PDF::Inspector::Text.analyze(pdf.render)
      expect(text_analysis.strings).to eq(['Page one', 'Page two'])
    end

    context 'with an invalid index' do
      let(:expected_content) { ['Page one', 'Page two', 'Page three'] }

      it 'does not destroy an invalid positve index' do
        pdf.delete_page(42)
        expect(pdf.page_number).to eq(3)
        text_analysis = PDF::Inspector::Text.analyze(pdf.render)
        expect(text_analysis.strings).to eq(expected_content)
      end

      it 'does not destroy an invalid negative index' do
        pdf.delete_page(-42)
        expect(pdf.page_number).to eq(3)
        text_analysis = PDF::Inspector::Text.analyze(pdf.render)
        expect(text_analysis.strings).to eq(expected_content)
      end
    end
  end

  describe '#page_number' do
    it 'is 1 for a new document' do
      pdf = described_class.new
      expect(pdf.page_number).to eq(1)
    end

    it 'is 0 for documents with no pages' do
      pdf = described_class.new(skip_page_creation: true)
      expect(pdf.page_number).to eq(0)
    end

    it 'is changed by go_to_page' do
      pdf = described_class.new
      10.times { pdf.start_new_page }
      pdf.go_to_page 3
      expect(pdf.page_number).to eq(3)
    end
  end

  describe 'on_page_create callback' do
    it 'is delegated from Document to renderer' do
      expect(pdf.respond_to?(:on_page_create)).to eq true
    end

    it 'is invoked with document' do
      called_with = nil

      pdf.renderer.on_page_create { |*args| called_with = args }

      pdf.start_new_page

      expect(called_with).to eq([pdf])
    end

    it 'is invoked for each new page' do
      trigger = instance_double('trigger')
      allow(trigger).to receive(:fire)

      pdf.renderer.on_page_create { trigger.fire }

      5.times { pdf.start_new_page }

      expect(trigger).to have_received(:fire).exactly(5).times
    end

    it 'is replaceable' do
      trigger1 = instance_double('trigger 1')
      allow(trigger1).to receive(:fire)

      trigger2 = instance_double('trigger 2')
      allow(trigger2).to receive(:fire)

      pdf.renderer.on_page_create { trigger1.fire }

      pdf.start_new_page

      pdf.renderer.on_page_create { trigger2.fire }

      pdf.start_new_page

      expect(trigger1).to have_received(:fire).once
      expect(trigger2).to have_received(:fire).once
    end

    it 'is clearable by calling on_page_create without a block' do
      trigger = instance_double('trigger')
      allow(trigger).to receive(:fire)

      pdf.renderer.on_page_create { trigger.fire }

      pdf.start_new_page

      pdf.renderer.on_page_create

      pdf.start_new_page

      expect(trigger).to have_received(:fire).once
    end
  end

  describe 'compression' do
    it 'does not compress the page content stream if compression is disabled' do
      pdf = described_class.new(compress: false)
      allow(pdf.page.content.stream).to receive(:compress!).and_return(true)

      pdf.text 'Hi There' * 20
      pdf.render

      expect(pdf.page.content.stream).to_not have_received(:compress!)
    end

    it 'compresses the page content stream if compression is enabled' do
      pdf = described_class.new(compress: true)
      allow(pdf.page.content.stream).to receive(:compress!).and_return(true)

      pdf.text 'Hi There' * 20
      pdf.render

      expect(pdf.page.content.stream).to have_received(:compress!).once
    end

    it 'results in a smaller file size when compressed' do
      doc_uncompressed = described_class.new
      doc_compressed = described_class.new(compress: true)
      [doc_compressed, doc_uncompressed].each do |pdf|
        pdf.font "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
        pdf.text '更可怕的是，同质化竞争对手可以按照URL中后面这个ID来遍历' * 10
      end

      expect(doc_compressed.render.length).to be <
        doc_uncompressed.render.length
    end
  end

  describe 'Dometadata' do
    it 'outputs strings as UTF-16 with a byte order mark' do
      pdf = described_class.new(info: { Author: 'Lóránt' })
      expect(pdf.state.store.info.object).to match(
        # UTF-16:     BOM L   ó   r   á   n   t
        %r{/Author\s*<feff004c00f3007200e1006e0074>}i
      )
    end
  end

  describe 'When reopening pages' do
    it 'modifies the content stream size' do
      pdf = described_class.new do
        text 'Page 1'
        start_new_page
        text 'Page 2'
        go_to_page 1
        text 'More for page 1'
      end

      # Indirectly verify that the actual length does not match dictionary
      # length.  If it isn't, a MalformedPDFError will be raised
      PDF::Inspector::Page.analyze(pdf.render)
    end

    it 'inserts pages after the current page when calling start_new_page' do
      pdf = described_class.new
      3.times do |i|
        pdf.text "Old page #{i + 1}"
        pdf.start_new_page
      end

      pdf.go_to_page 1
      pdf.start_new_page
      pdf.text 'New page 2'

      expect(pdf.page_number).to eq(2)

      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.size).to eq(5)
      expect(pages[1][:strings]).to eq(['New page 2'])
      expect(pages[2][:strings]).to eq(['Old page 2'])
    end

    it 'restores the layout of the page' do
      doc = described_class.new do
        start_new_page layout: :landscape
      end

      lsize = [doc.bounds.width, doc.bounds.height]

      expect([doc.bounds.width, doc.bounds.height]).to eq lsize
      doc.go_to_page 1
      expect([doc.bounds.width, doc.bounds.height]).to eq lsize.reverse
    end

    it 'restores the margin box of the page' do
      doc = described_class.new(margin: [100, 100])
      page1_bounds = doc.bounds

      doc.start_new_page(margin: [200, 200])

      expect([doc.bounds.width, doc.bounds.height]).to eq(
        [page1_bounds.width - 200, page1_bounds.height - 200]
      )

      doc.go_to_page(1)

      expect(doc.bounds.width).to eq page1_bounds.width
      expect(doc.bounds.height).to eq page1_bounds.height
    end
  end

  describe 'When setting page size' do
    it 'defaults to LETTER' do
      pdf = described_class.new
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.first[:size]).to eq(PDF::Core::PageGeometry::SIZES['LETTER'])
    end

    (PDF::Core::PageGeometry::SIZES.keys - ['LETTER']).each do |k|
      it "provides #{k} geometry" do
        pdf = described_class.new(page_size: k)
        pages = PDF::Inspector::Page.analyze(pdf.render).pages
        expect(pages.first[:size]).to eq(PDF::Core::PageGeometry::SIZES[k])
      end
    end

    it 'allows custom page size' do
      pdf = described_class.new(page_size: [1920, 1080])
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.first[:size]).to eq([1920, 1080])
    end

    it 'retains page size by default when starting a new page' do
      pdf = described_class.new(page_size: 'LEGAL')
      pdf.start_new_page
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      pages.each do |page|
        expect(page[:size]).to eq(PDF::Core::PageGeometry::SIZES['LEGAL'])
      end
    end
  end

  describe 'When setting page layout' do
    it 'reverses coordinates for landscape' do
      pdf = described_class.new(page_size: 'A4', page_layout: :landscape)
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      expect(pages.first[:size]).to eq(
        PDF::Core::PageGeometry::SIZES['A4'].reverse
      )
    end

    it 'retains page layout by default when starting a new page' do
      pdf = described_class.new(page_layout: :landscape)
      pdf.start_new_page(trace: true)
      pages = PDF::Inspector::Page.analyze(pdf.render).pages
      pages.each do |page|
        expect(page[:size]).to eq(
          PDF::Core::PageGeometry::SIZES['LETTER'].reverse
        )
      end
    end

    it 'swaps the bounds when starting a new page with different layout' do
      pdf = described_class.new
      size = [pdf.bounds.width, pdf.bounds.height]
      pdf.start_new_page(layout: :landscape)
      expect([pdf.bounds.width, pdf.bounds.height]).to eq(size.reverse)
    end
  end

  describe '#mask' do
    it 'allows transactional restoration of attributes' do
      pdf = described_class.new
      y = pdf.y
      line_width = pdf.line_width
      pdf.mask(:y, :line_width) do
        pdf.y = y + 1
        pdf.line_width = line_width + 1
        expect(pdf.y).to_not eq(y)
        expect(pdf.line_width).to_not eq(line_width)
      end
      expect(pdf.y).to eq(y)
      expect(pdf.line_width).to eq(line_width)
    end
  end

  describe '#render' do
    it 'returns a 8 bit encoded string on a m17n aware VM' do
      pdf = described_class.new(page_size: 'A4', page_layout: :landscape)
      pdf.line [100, 100], [200, 200]
      str = pdf.render
      expect(str.encoding.to_s).to eq('ASCII-8BIT')
    end

    it 'triggers before_render callbacks just before rendering' do
      pdf = described_class.new

      # Verify the order: finalize -> fire callbacks -> render body
      allow(pdf.renderer).to receive(:finalize_all_page_contents)
        .and_call_original

      trigger = instance_double('trigger')
      allow(trigger).to receive(:fire)

      pdf.renderer.before_render { trigger.fire }

      allow(pdf.renderer).to receive(:render_body).and_call_original

      pdf.render(StringIO.new)

      expect(pdf.renderer).to have_received(:finalize_all_page_contents)
        .ordered
      expect(trigger).to have_received(:fire).ordered
      expect(pdf.renderer).to have_received(:render_body).ordered
    end

    it 'is idempotent' do
      pdf = described_class.new

      contents = pdf.render
      contents2 = pdf.render
      expect(contents2).to eq(contents)
    end
  end

  describe 'PDF file versions' do
    it 'defaults to 1.3' do
      pdf = described_class.new
      str = pdf.render
      expect(str[0, 8]).to eq('%PDF-1.3')
    end

    it 'allows the default to be changed' do
      pdf = described_class.new
      pdf.renderer.min_version(1.4)
      str = pdf.render
      expect(str[0, 8]).to eq('%PDF-1.4')
    end
  end

  describe '#go_to_page' do
    it 'has 2 pages after calling start_new_page and go_to_page' do
      pdf = described_class.new
      pdf.text 'James'
      pdf.start_new_page
      pdf.text 'Anthony'
      pdf.go_to_page(1)
      pdf.text 'Healy'

      page_counter = PDF::Inspector::Page.analyze(pdf.render)
      expect(page_counter.pages.size).to eq(2)
    end

    it 'correctlies add text to pages' do
      pdf = described_class.new
      pdf.text 'James'
      pdf.start_new_page
      pdf.text 'Anthony'
      pdf.go_to_page(1)
      pdf.text 'Healy'

      text = PDF::Inspector::Text.analyze(pdf.render)

      expect(text.strings.size).to eq(3)
      expect(text.strings.include?('James')).to eq(true)
      expect(text.strings.include?('Anthony')).to eq(true)
      expect(text.strings.include?('Healy')).to eq(true)
    end
  end

  describe 'content stream characteristics' do
    it 'has 1 single content stream for a single page PDF' do
      pdf = described_class.new
      pdf.text 'James'
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      streams = hash.values.select { |obj| obj.is_a?(PDF::Reader::Stream) }

      expect(streams.size).to eq(1)
    end

    it 'has 1 single content stream for a single page PDF, even if go_to_page '\
      'is used' do
      pdf = described_class.new
      pdf.text 'James'
      pdf.go_to_page(1)
      pdf.text 'Healy'
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      streams = hash.values.select { |obj| obj.is_a?(PDF::Reader::Stream) }

      expect(streams.size).to eq(1)
    end
  end

  describe '#number_pages' do
    let(:pdf) { described_class.new(skip_page_creation: true) }

    it "replaces the '<page>' string with the proper page number" do
      pdf.start_new_page
      allow(pdf).to receive(:text_box)
      pdf.number_pages '<page>, test', page_filter: :all
      expect(pdf).to have_received(:text_box).with('1, test', height: 50)
    end

    it "replaces the '<total>' string with the total page count" do
      pdf.start_new_page
      allow(pdf).to receive(:text_box)
      pdf.number_pages 'test, <total>', page_filter: :all
      expect(pdf).to have_received(:text_box).with('test, 1', height: 50)
    end

    it 'must print each page if given the :all page_filter' do
      10.times { pdf.start_new_page }
      allow(pdf).to receive(:text_box)
      pdf.number_pages 'test', page_filter: :all
      expect(pdf).to have_received(:text_box).exactly(10).times
    end

    it 'must print each page if no :page_filter is specified' do
      10.times { pdf.start_new_page }
      allow(pdf).to receive(:text_box)
      pdf.number_pages 'test'
      expect(pdf).to have_received(:text_box).exactly(10).times
    end

    it 'must not print the page number if given a nil filter' do
      10.times { pdf.start_new_page }
      allow(pdf).to receive(:text_box)
      pdf.number_pages 'test', page_filter: nil
      expect(pdf).to_not have_received(:text_box)
    end

    context 'with start_count_at option' do
      [1, 2].each do |startat|
        context "equal to #{startat}" do
          it 'increments the pages' do
            2.times { pdf.start_new_page }
            options = { page_filter: :all, start_count_at: startat }
            allow(pdf).to receive(:text_box)
            pdf.number_pages '<page> <total>', options

            expect(pdf).to have_received(:text_box)
              .with("#{startat} 2", height: 50)
            expect(pdf).to have_received(:text_box)
              .with("#{startat + 1} 2", height: 50)
          end
        end
      end

      [0, nil].each do |val|
        context "equal to #{val}" do
          it 'defaults to start at page 1' do
            3.times { pdf.start_new_page }
            options = { page_filter: :all, start_count_at: val }
            allow(pdf).to receive(:text_box)
            pdf.number_pages '<page> <total>', options

            expect(pdf).to have_received(:text_box).with('1 3', height: 50)
            expect(pdf).to have_received(:text_box).with('2 3', height: 50)
            expect(pdf).to have_received(:text_box).with('3 3', height: 50)
          end
        end
      end
    end

    context 'with total_pages option' do
      it 'allows the total pages count to be overridden' do
        2.times { pdf.start_new_page }
        allow(pdf).to receive(:text_box)
        pdf.number_pages '<page> <total>', page_filter: :all, total_pages: 10

        expect(pdf).to have_received(:text_box).with('1 10', height: 50)
        expect(pdf).to have_received(:text_box).with('2 10', height: 50)
      end
    end

    context 'with special page filter' do
      describe 'such as :odd' do
        it 'increments the pages' do
          3.times { pdf.start_new_page }
          allow(pdf).to receive(:text_box)
          pdf.number_pages '<page> <total>', page_filter: :odd

          expect(pdf).to have_received(:text_box).with('1 3', height: 50)
          expect(pdf).to have_received(:text_box).with('3 3', height: 50)
          expect(pdf).to_not have_received(:text_box).with('2 3', height: 50)
        end
      end

      describe 'missing' do
        it 'does not print any page numbers' do
          3.times { pdf.start_new_page }
          allow(pdf).to receive(:text_box)
          pdf.number_pages '<page> <total>', page_filter: nil

          expect(pdf).to_not have_received(:text_box)
        end
      end
    end

    context 'with both a special page filter and a start_count_at parameter' do
      describe 'such as :odd and 7' do
        it 'increments the pages' do
          3.times { pdf.start_new_page }
          allow(pdf).to receive(:text_box)
          pdf.number_pages '<page> <total>',
            page_filter: :odd,
            start_count_at: 5

          expect(pdf).to_not have_received(:text_box).with('1 3', height: 50)
          # page 1
          expect(pdf).to have_received(:text_box).with('5 3', height: 50)

          # page 2
          expect(pdf).to_not have_received(:text_box).with('6 3', height: 50)

          # page 3
          expect(pdf).to have_received(:text_box).with('7 3', height: 50)
        end
      end

      context 'with some crazy proc and 2' do
        it 'increments the pages' do
          6.times { pdf.start_new_page }
          options = {
            page_filter: ->(p) { p != 2 && p != 5 },
            start_count_at: 4
          }
          allow(pdf).to receive(:text_box)
          pdf.number_pages '<page> <total>', options

          # page 1
          expect(pdf).to have_received(:text_box).with('4 6', height: 50)

          # page 2
          expect(pdf).to_not have_received(:text_box).with('5 6', height: 50)

          # page 3
          expect(pdf).to have_received(:text_box).with('6 6', height: 50)

          # page 4
          expect(pdf).to have_received(:text_box).with('7 6', height: 50)

          # page 5
          expect(pdf).to_not have_received(:text_box).with('8 6', height: 50)

          # page 6
          expect(pdf).to have_received(:text_box).with('9 6', height: 50)
        end
      end
    end

    describe 'height option' do
      before do
        pdf.start_new_page
      end

      it 'with 10 height' do
        allow(pdf).to receive(:text_box)
        pdf.number_pages '<page> <total>', height: 10
        expect(pdf).to have_received(:text_box).with('1 1', height: 10)
      end

      it 'with nil height' do
        allow(pdf).to receive(:text_box)
        pdf.number_pages '<page> <total>', height: nil
        expect(pdf).to have_received(:text_box).with('1 1', height: nil)
      end

      it 'with no height' do
        allow(pdf).to receive(:text_box)
        pdf.number_pages '<page> <total>'
        expect(pdf).to have_received(:text_box).with('1 1', height: 50)
      end
    end
  end

  describe '#page_match?' do
    let(:pdf) do
      described_class.new(skip_page_creation: true) do |pdf|
        10.times { pdf.start_new_page }
      end
    end

    it 'returns nil given no filter' do
      expect(pdf).to_not be_page_match(:nil, 1)
    end

    it 'must provide an :all filter' do
      expect((1..pdf.page_count).all? { |i| pdf.page_match?(:all, i) })
        .to eq true
    end

    it 'must provide an :odd filter' do
      odd, even = (1..pdf.page_count).partition(&:odd?)
      expect(odd.all? { |i| pdf.page_match?(:odd, i) }).to eq true
      expect(even).to_not(be_any { |i| pdf.page_match?(:odd, i) })
    end

    it 'must be able to filter by an array of page numbers' do
      fltr = [1, 2, 7]
      expect((1..10).select { |i| pdf.page_match?(fltr, i) }).to eq([1, 2, 7])
    end

    it 'must be able to filter by a range of page numbers' do
      fltr = 2..4
      expect((1..10).select { |i| pdf.page_match?(fltr, i) }).to eq([2, 3, 4])
    end

    it 'must be able to filter by an arbitrary proc' do
      fltr = ->(x) { x == 1 || (x % 3).zero? }
      expect((1..10).select { |i| pdf.page_match?(fltr, i) })
        .to eq([1, 3, 6, 9])
    end
  end
end
