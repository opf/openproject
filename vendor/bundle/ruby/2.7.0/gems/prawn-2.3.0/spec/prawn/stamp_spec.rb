# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Stamp do
  describe 'create_stamp before any page is added' do
    let(:pdf) { Prawn::Document.new(skip_page_creation: true) }

    it 'works with the font class' do
      # If anything goes wrong, Prawn::Errors::NotOnPage will be raised
      pdf.create_stamp('my_stamp') do
        pdf.font.height
      end
    end

    it 'works with setting color' do
      # If anything goes wrong, Prawn::Errors::NotOnPage will be raised
      pdf.create_stamp('my_stamp') do
        pdf.fill_color = 'ff0000'
      end
    end
  end

  describe '#stamp_at' do
    let(:pdf) { create_pdf }

    it 'works' do
      pdf.create_stamp('MyStamp')
      pdf.stamp_at('MyStamp', [100, 200])
      # I had modified PDF::Inspector::XObject to receive the
      # invoke_xobject message and count the number of times it was
      # called, but it was only called once, so I reverted checking the
      # output with a regular expression
      expect(pdf.render).to match(%r{/Stamp1 Do.*?}m)
    end
  end

  describe 'Document with a stamp' do
    let(:pdf) { create_pdf }

    it 'raises NameTaken error when attempt to create stamp with '\
       'same name as an existing stamp' do
      pdf.create_stamp('MyStamp')
      expect do
        pdf.create_stamp('MyStamp')
      end.to raise_error(Prawn::Errors::NameTaken)
    end

    it 'raises InvalidName error when attempt to create stamp with '\
        'a blank name' do
      expect do
        pdf.create_stamp('')
      end.to raise_error(Prawn::Errors::InvalidName)
    end

    it 'a new XObject should be defined for each stamp created' do
      pdf.create_stamp('MyStamp')
      pdf.create_stamp('AnotherStamp')
      pdf.stamp('MyStamp')
      pdf.stamp('AnotherStamp')

      inspector = PDF::Inspector::XObject.analyze(pdf.render)
      xobjects = inspector.page_xobjects.last
      expect(xobjects.length).to eq(2)
    end

    it 'calling stamp with a name that does not match an existing stamp ' \
      'should raise_error UndefinedObjectName' do
      pdf.create_stamp('MyStamp')
      expect do
        pdf.stamp('OtherStamp')
      end.to raise_error(Prawn::Errors::UndefinedObjectName)
    end

    it 'stamp should be drawn into the document each time stamp is called' do
      pdf.create_stamp('MyStamp')
      pdf.stamp('MyStamp')
      pdf.stamp('MyStamp')
      pdf.stamp('MyStamp')
      # I had modified PDF::Inspector::XObject to receive the
      # invoke_xobject message and count the number of times it was
      # called, but it was only called once, so I reverted checking the
      # output with a regular expression
      expect(pdf.render).to match(%r{(/Stamp1 Do.*?){3}}m)
    end

    it 'stamp should render clickable links' do
      pdf.create_stamp 'bar' do
        pdf.text '<b>Prawn</b> <link href="http://github.com">GitHub</link>',
          inline_format: true
      end
      pdf.stamp 'bar'

      output = pdf.render
      objects = output.split('endobj')

      objects.each do |obj|
        next unless %r{/Type /Page$}.match?(obj)

        # The page object must contain the annotation reference
        # to render a clickable link
        expect(obj).to match(%r{^/Annots \[\d \d .\]$})
      end
    end

    it 'resources added during stamp creation should be added to the ' \
      'stamp XObject, not the page' do
      pdf.create_stamp('MyStamp') do
        pdf.transparent(0.5) { pdf.circle([100, 100], 10) }
      end
      pdf.stamp('MyStamp')

      # Inspector::XObject does not give information about resources, so
      # resorting to string matching

      output = pdf.render
      objects = output.split('endobj')
      objects.each do |object|
        if %r{/Type /Page$}.match?(object)
          expect(object).to_not match(%r{/ExtGState})
        elsif %r{/Type /XObject$}.match?(object)
          expect(object).to match(%r{/ExtGState})
        end
      end
    end

    it 'stamp stream should be wrapped in a graphic state' do
      pdf.create_stamp('MyStamp') do
        pdf.text "This should have a 'q' before it and a 'Q' after it"
      end
      pdf.stamp('MyStamp')
      stamps = PDF::Inspector::XObject.analyze(pdf.render)
      expect(stamps.xobject_streams[:Stamp1].data.chomp).to match(/q(.|\s)*Q\Z/)
    end

    it 'does not add to the page graphic state stack' do
      expect(pdf.state.page.stack.stack.size).to eq(1)

      pdf.create_stamp('MyStamp') do
        pdf.save_graphics_state
        pdf.save_graphics_state
        pdf.save_graphics_state
        pdf.text "This should have a 'q' before it and a 'Q' after it"
        pdf.restore_graphics_state
      end
      expect(pdf.state.page.stack.stack.size).to eq(1)
    end

    it 'is able to change fill and stroke colors within the stamp stream' do
      pdf.create_stamp('MyStamp') do
        pdf.fill_color(100, 100, 20, 0)
        pdf.stroke_color(100, 100, 20, 0)
      end
      pdf.stamp('MyStamp')
      stamps = PDF::Inspector::XObject.analyze(pdf.render)
      stamp_stream = stamps.xobject_streams[:Stamp1].data
      expect(stamp_stream).to include("/DeviceCMYK cs\n1.0 1.0 0.2 0.0 scn")
      expect(stamp_stream).to include("/DeviceCMYK CS\n1.0 1.0 0.2 0.0 SCN")
    end

    it 'saves the color space even when same as current page color space' do
      pdf.stroke_color(100, 100, 20, 0)
      pdf.create_stamp('MyStamp') do
        pdf.stroke_color(100, 100, 20, 0)
      end
      pdf.stamp('MyStamp')
      stamps = PDF::Inspector::XObject.analyze(pdf.render)
      stamp_stream = stamps.xobject_streams[:Stamp1].data
      expect(stamp_stream).to include("/DeviceCMYK CS\n1.0 1.0 0.2 0.0 SCN")
    end
  end
end
