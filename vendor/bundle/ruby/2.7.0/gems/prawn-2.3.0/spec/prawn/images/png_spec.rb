# frozen_string_literal: true

# Spec'ing the PNG class. Not complete yet - still needs to check the
# contents of palette and transparency to ensure they're correct.
# Need to find files that have these sections first.
#
# see http://www.w3.org/TR/PNG/ for a detailed description of the PNG spec,
# particuarly Table 11.1 for the different color types

require 'spec_helper'

describe Prawn::Images::PNG do
  describe 'When making a pdf file with png images' do
    image_dir = "#{Prawn::BASEDIR}/data/images"
    images = [
      ['Type 0', "#{image_dir}/web-links.png"],
      ['Type 0 with transparency', "#{image_dir}/ruport_type0.png"],
      ['Type 2', "#{image_dir}/ruport.png"],
      ['Type 2 with transparency', "#{image_dir}/arrow2.png"],
      ['Type 3', "#{image_dir}/indexed_color.png"],
      ['Type 3 with transparency', "#{image_dir}/indexed_transparency.png"],
      ['Type 4', "#{image_dir}/page_white_text.png"],
      ['Type 6', "#{image_dir}/dice.png"],
      ['Type 6 in 16bit', "#{image_dir}/16bit.png"]
    ]

    images.each do |header, file|
      describe "and the image is #{header}" do
        it 'does not error' do
          expect do
            Prawn::Document.generate("#{header}.pdf", page_size: 'A5') do
              fill_color '00FF00'

              fill_rectangle bounds.top_left, bounds.width, bounds.height
              text header

              image file, at: [50, 450]
            end
          end.to_not raise_error
        end
      end
    end
  end

  describe 'When reading a greyscale PNG file (color type 0)' do
    let(:data_filename) { "#{Prawn::DATADIR}/images/web-links.dat" }
    let(:img_data) { File.binread("#{Prawn::DATADIR}/images/web-links.png") }

    it 'reads the attributes from the header chunk correctly' do
      png = described_class.new(img_data)

      expect(png.width).to eq(21)
      expect(png.height).to eq(14)
      expect(png.bits).to eq(8)
      expect(png.color_type).to eq(0)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'reads the image data chunk correctly' do
      png = described_class.new(img_data)
      data = Zlib::Inflate.inflate(File.binread(data_filename))
      expect(png.img_data).to eq(data)
    end
  end

  describe 'When reading a greyscale PNG with transparency (color type 0)' do
    let(:img_data) { File.binread("#{Prawn::DATADIR}/images/ruport_type0.png") }

    # In a greyscale type 0 PNG image, the tRNS chunk should contain a single
    # value that indicates the color that should be interpreted as transparent.
    #
    # http://www.w3.org/TR/PNG/#11tRNS
    it 'reads the tRNS chunk correctly' do
      png = described_class.new(img_data)
      expect(png.transparency[:grayscale]).to eq(255)
    end
  end

  describe 'When reading an RGB PNG file (color type 2)' do
    let(:data_filename) { "#{Prawn::DATADIR}/images/ruport_data.dat" }
    let(:img_data) { File.binread("#{Prawn::DATADIR}/images/ruport.png") }

    it 'reads the attributes from the header chunk correctly' do
      png = described_class.new(img_data)

      expect(png.width).to eq(258)
      expect(png.height).to eq(105)
      expect(png.bits).to eq(8)
      expect(png.color_type).to eq(2)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'reads the image data chunk correctly' do
      png = described_class.new(img_data)
      data = Zlib::Inflate.inflate(File.binread(data_filename))
      expect(png.img_data).to eq(data)
    end
  end

  describe 'When reading an RGB PNG file with transparency (color type 2)' do
    let(:img_data) { File.binread("#{Prawn::DATADIR}/images/arrow2.png") }

    # In a RGB type 2 PNG image, the tRNS chunk should contain a single RGB
    # value that indicates the color that should be interpreted as transparent.
    # In this case it's green.
    #
    # http://www.w3.org/TR/PNG/#11tRNS
    it 'reads the tRNS chunk correctly' do
      png = described_class.new(img_data)
      expect(png.transparency[:rgb]).to eq([0, 255, 0])
    end
  end

  describe 'When reading an indexed color PNG file with transparency '\
    '(color type 3)' do
    let(:filename) { "#{Prawn::DATADIR}/images/indexed_transparency.png" }
    let(:color_filename) do
      "#{Prawn::DATADIR}/images/indexed_transparency_color.dat"
    end
    let(:transparency_filename) do
      "#{Prawn::DATADIR}/images/indexed_transparency_alpha.dat"
    end
    let(:img_data) { File.binread(filename) }
    let(:png) { described_class.new(img_data) }

    it 'reads the attributes from the header chunk correctly' do
      expect(png.width).to eq(200)
      expect(png.height).to eq(200)
      expect(png.bits).to eq(8)
      expect(png.color_type).to eq(3)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'reads the image data correctly' do
      data = Zlib::Inflate.inflate(File.binread(color_filename))
      expect(png.img_data).to eq(data)
    end

    it 'reads the image transparency correctly' do
      png.split_alpha_channel!

      data = Zlib::Inflate.inflate(File.binread(transparency_filename))
      expect(png.alpha_channel).to eq(data)
    end
  end

  describe 'When reading an indexed color PNG file (color type 3)' do
    let(:data_filename) { "#{Prawn::DATADIR}/images/indexed_color.dat" }
    let(:img_data) do
      File.binread("#{Prawn::DATADIR}/images/indexed_color.png")
    end

    it 'reads the attributes from the header chunk correctly' do
      png = described_class.new(img_data)

      expect(png.width).to eq(150)
      expect(png.height).to eq(200)
      expect(png.bits).to eq(8)
      expect(png.color_type).to eq(3)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'reads the image data chunk correctly' do
      png = described_class.new(img_data)
      data = Zlib::Inflate.inflate(File.binread(data_filename))
      expect(png.img_data).to eq(data)
    end
  end

  describe 'When reading a greyscale+alpha PNG file (color type 4)' do
    let(:color_data_filename) do
      "#{Prawn::DATADIR}/images/page_white_text.color"
    end
    let(:alpha_data_filename) do
      "#{Prawn::DATADIR}/images/page_white_text.alpha"
    end
    let(:img_data) do
      File.binread("#{Prawn::DATADIR}/images/page_white_text.png")
    end

    it 'reads the attributes from the header chunk correctly' do
      png = described_class.new(img_data)

      expect(png.width).to eq(16)
      expect(png.height).to eq(16)
      expect(png.bits).to eq(8)
      expect(png.color_type).to eq(4)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'correctly returns the raw image data (with no alpha channel) from '\
      'the image data chunk' do
      png = described_class.new(img_data)
      png.split_alpha_channel!
      data = File.binread(color_data_filename)
      expect(png.img_data).to eq(data)
    end

    it 'correctly extracts the alpha channel data from the image data chunk' do
      png = described_class.new(img_data)
      png.split_alpha_channel!
      data = File.binread(alpha_data_filename)
      expect(png.alpha_channel).to eq(data)
    end
  end

  describe 'When reading an RGB+alpha PNG file (color type 6)' do
    let(:color_data_filename) { "#{Prawn::DATADIR}/images/dice.color" }
    let(:alpha_data_filename) { "#{Prawn::DATADIR}/images/dice.alpha" }
    let(:img_data) { File.binread("#{Prawn::DATADIR}/images/dice.png") }

    it 'reads the attributes from the header chunk correctly' do
      png = described_class.new(img_data)

      expect(png.width).to eq(320)
      expect(png.height).to eq(240)
      expect(png.bits).to eq(8)
      expect(png.color_type).to eq(6)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'correctly returns the raw image data (with no alpha channel) from '\
      'the image data chunk' do
      png = described_class.new(img_data)
      png.split_alpha_channel!
      data = File.binread(color_data_filename)
      expect(png.img_data).to eq(data)
    end

    it 'correctly extracts the alpha channel data from the image data chunk' do
      png = described_class.new(img_data)
      png.split_alpha_channel!
      data = File.binread(alpha_data_filename)
      expect(png.alpha_channel).to eq(data)
    end
  end

  describe 'When reading a 16bit RGB+alpha PNG file (color type 6)' do
    let(:color_data_filename) { "#{Prawn::DATADIR}/images/16bit.color" }
    # alpha channel truncated to 8-bit
    let(:alpha_data_filename) { "#{Prawn::DATADIR}/images/16bit.alpha" }
    let(:img_data) { File.binread("#{Prawn::DATADIR}/images/16bit.png") }

    it 'reads the attributes from the header chunk correctly' do
      png = described_class.new(img_data)

      expect(png.width).to eq(32)
      expect(png.height).to eq(32)
      expect(png.bits).to eq(16)
      expect(png.color_type).to eq(6)
      expect(png.compression_method).to eq(0)
      expect(png.filter_method).to eq(0)
      expect(png.interlace_method).to eq(0)
    end

    it 'correctly returns the raw image data (with no alpha channel) from '\
      'the image data chunk' do
      png = described_class.new(img_data)
      png.split_alpha_channel!
      data = File.binread(color_data_filename)
      expect(png.img_data).to eq(data)
    end

    it 'correctly extracts the alpha channel data from the image data chunk' do
      png = described_class.new(img_data)
      png.split_alpha_channel!
      data = File.binread(alpha_data_filename)
      expect(png.alpha_channel).to eq(data)
    end
  end
end
