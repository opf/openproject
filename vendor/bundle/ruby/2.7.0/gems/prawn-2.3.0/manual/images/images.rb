# frozen_string_literal: true

# Examples for embedding images.

require_relative '../example_helper'

Prawn::ManualBuilder::Example.generate('images.pdf', page_size: 'FOLIO') do
  package 'images' do |p|
    p.section 'Basics' do |s|
      s.example 'plain_image'
      s.example 'absolute_position'
    end

    p.section 'Relative Positioning' do |s|
      s.example 'horizontal'
      s.example 'vertical'
    end

    p.section 'Size' do |s|
      s.example 'width_and_height'
      s.example 'scale'
      s.example 'fit'
    end

    p.intro do
      prose <<-TEXT
        Embedding images on PDF documents is fairly easy. Prawn supports both
        JPG and PNG images.

        The examples show:
      TEXT

      list(
        'How to add an image to a page',
        'How place the image on a specific position',
        'How to configure the image dimensions by setting the width and '\
          'height or by scaling it'
      )
    end
  end
end
