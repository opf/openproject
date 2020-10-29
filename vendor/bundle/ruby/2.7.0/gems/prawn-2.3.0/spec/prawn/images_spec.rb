# frozen_string_literal: true

require 'spec_helper'
require 'set'
require 'pathname'

describe Prawn::Images do
  let(:pdf) { create_pdf }
  let(:filename) { "#{Prawn::DATADIR}/images/pigs.jpg" }

  it "onlies embed an image once, even if it's added multiple times" do
    pdf.image filename, at: [100, 100]
    pdf.image filename, at: [300, 300]

    output = pdf.render
    images = PDF::Inspector::XObject.analyze(output)
    # there should be 2 images in the page resources
    expect(images.page_xobjects.first.size).to eq(2)
    # but only 1 image xobject
    expect(output.scan(%r{/Type /XObject}).size).to eq(1)
  end

  it 'returns the image info object' do
    info = pdf.image(filename)

    expect(info).to be_a_kind_of(Prawn::Images::JPG)

    expect(info.height).to eq(453)
  end

  it 'accepts IO objects' do
    file = File.open(filename, 'rb')
    info = pdf.image(file)

    expect(info.height).to eq(453)
  end

  it 'rewinds IO objects to be able to embed them multiply' do
    file = File.open(filename, 'rb')

    pdf.image(file)
    info = pdf.image(file)
    expect(info.height).to eq(453)
  end

  it 'does not close passed-in IO objects' do
    file = File.open(filename, 'rb')
    _info = pdf.image(file)

    expect(file).to_not be_closed
  end

  it 'accepts Pathname objects' do
    info = pdf.image(Pathname.new(filename))
    expect(info.height).to eq(453)
  end

  describe 'closes opened files again after getting Pathnames', issue: 975 do
    describe 'spec with File message spy' do
      let(:not_filename) { 'non-existent filename' }
      let(:pathname_double) { instance_double('Pathname', file?: true) }

      before do
        file_content = File.new(filename, 'rb').read
        allow(Pathname).to receive(:new).with(not_filename) { pathname_double }
        allow(pathname_double).to receive(:binread) { file_content }
      end

      it 'uses only binread, which closes opened files' do
        # this implicitly tests that a file handle is closed again
        # because only stubbed binread can be called on not_filename
        _info = pdf.image(not_filename)
        expect(pathname_double).to have_received(:binread)
      end
    end

    system_has_lsof = system('lsof -v > /dev/null 2>&1')
    system_has_grep = system('grep --version > /dev/null 2>&1')
    if system_has_lsof && system_has_grep
      it 'closes opened files, spec with lsof' do
        gc_was_disabled = GC.disable # GC of File would close the file
        open_before = `lsof -c ruby | grep "#{filename}"`
        _info = pdf.image(Pathname.new(filename))
        open_after = `lsof -c ruby | grep "#{filename}"`
        GC.enable unless gc_was_disabled
        expect(open_after).to eq(open_before)
      end
    end

    if RUBY_PLATFORM != 'java'
      it 'closes opened files, spec with ObjectSpace' do
        gc_was_disabled = GC.disable # GC of File would close the file
        open_before = ObjectSpace.each_object(File).count { |f| !f.closed? }
        _info = pdf.image(Pathname.new(filename))
        open_after = ObjectSpace.each_object(File).count { |f| !f.closed? }
        GC.enable unless gc_was_disabled
        expect(open_after).to eq(open_before)
      end
    end
  end

  describe 'setting the length of the bytestream' do
    it 'correctlies work with images from Pathname objects' do
      pdf.image(Pathname.new(filename))
      expect(pdf).to have_parseable_xobjects
    end

    it 'correctlies work with images from IO objects' do
      pdf.image(File.open(filename, 'rb'))
      expect(pdf).to have_parseable_xobjects
    end

    it 'correctlies work with images from IO objects not set to mode rb' do
      pdf.image(File.open(filename, 'r'))
      expect(pdf).to have_parseable_xobjects
    end
  end

  it 'raise_errors an UnsupportedImageType if passed a BMP' do
    filename = "#{Prawn::DATADIR}/images/tru256.bmp"
    expect { pdf.image filename, at: [100, 100] }
      .to raise_error(Prawn::Errors::UnsupportedImageType)
  end

  it 'raise_errors an UnsupportedImageType if passed an interlaced PNG' do
    filename = "#{Prawn::DATADIR}/images/dice_interlaced.png"
    expect { pdf.image filename, at: [100, 100] }
      .to raise_error(Prawn::Errors::UnsupportedImageType)
  end

  it 'bumps PDF version to 1.5 or greater on embedding 16-bit PNGs' do
    pdf.image "#{Prawn::DATADIR}/images/16bit.png"
    expect(pdf.state.version).to be >= 1.5
  end

  it 'embeds 16-bit alpha channels for 16-bit PNGs' do
    pdf.image "#{Prawn::DATADIR}/images/16bit.png"

    output = pdf.render
    expect(output).to match(%r{/BitsPerComponent 16})
    expect(output).to_not match(%r{/BitsPerComponent 8})
  end

  it 'flows an image to a new page if it will not fit on a page' do
    pdf.image filename, fit: [600, 600]
    pdf.image filename, fit: [600, 600]
    output = StringIO.new(pdf.render, 'r+')
    hash = PDF::Reader::ObjectHash.new(output)
    pages = hash.values.find do |obj|
      obj.is_a?(Hash) && obj[:Type] == :Pages
    end[:Kids]
    expect(pages.size).to eq(2)
    expect(hash[pages[0]][:Resources][:XObject].keys).to eq([:I1])
    expect(hash[pages[1]][:Resources][:XObject].keys).to eq([:I2])
  end

  it 'does not flow an image to a new page if it will fit on one page' do
    pdf.image filename, fit: [400, 400]
    pdf.image filename, fit: [400, 400]
    output = StringIO.new(pdf.render, 'r+')
    hash = PDF::Reader::ObjectHash.new(output)
    pages = hash.values.find do |obj|
      obj.is_a?(Hash) && obj[:Type] == :Pages
    end[:Kids]
    expect(pages.size).to eq(1)
    expect(Set.new(hash[pages[0]][:Resources][:XObject].keys)).to eq(
      Set.new(%i[I1 I2])
    )
  end

  it 'does not start a new page just for a stretchy bounding box' do
    allow(pdf).to receive(:start_new_page)
    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
      pdf.image filename
    end
    expect(pdf).to_not have_received(:start_new_page)
  end

  describe ':fit option' do
    it 'fits inside the defined constraints' do
      info = pdf.image filename, fit: [100, 400]
      expect(info.scaled_width).to be <= 100
      expect(info.scaled_height).to be <= 400

      info = pdf.image filename, fit: [400, 100]
      expect(info.scaled_width).to be <= 400
      expect(info.scaled_height).to be <= 100

      info = pdf.image filename, fit: [604, 453]
      expect(info.scaled_width).to eq(604)
      expect(info.scaled_height).to eq(453)
    end

    it 'moves text position' do
      y = pdf.y
      pdf.image filename, fit: [100, 400]
      expect(pdf.y).to be < y
    end
  end

  describe ':at option' do
    it 'does not move text position' do
      y = pdf.y
      pdf.image filename, at: [100, 400]
      expect(pdf.y).to eq(y)
    end
  end

  describe ':width option without :height option' do
    it 'scales the width and height' do
      info = pdf.image filename, width: 225
      expect(info.scaled_height).to eq(168.75)
      expect(info.scaled_width).to eq(225.0)
    end
  end

  describe ':height option without :width option' do
    it 'scales the width and height' do
      info = pdf.image filename, height: 225
      expect(info.scaled_height).to eq(225.0)
      expect(info.scaled_width).to eq(300.0)
    end
  end
end
