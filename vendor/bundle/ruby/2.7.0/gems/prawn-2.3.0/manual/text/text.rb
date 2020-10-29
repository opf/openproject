# frozen_string_literal: true

# Examples for text rendering.

require '../example_helper'

Prawn::ManualBuilder::Example.generate('text.pdf', page_size: 'FOLIO') do
  package 'text' do |p|
    p.section 'Basics' do |s|
      s.example 'free_flowing_text'
      s.example 'positioned_text'
      s.example 'text_box_overflow'
      s.example 'text_box_excess'
      s.example 'column_box'
    end

    p.section 'Styling' do |s|
      s.example 'font'
      s.example 'font_size'
      s.example 'font_style'
      s.example 'color'
      s.example 'alignment'
      s.example 'leading'
      s.example 'kerning_and_character_spacing'
      s.example 'paragraph_indentation'
      s.example 'rotation'
    end

    p.section 'Advanced Styling' do |s|
      s.example 'inline'
      s.example 'formatted_text'
      s.example 'formatted_callbacks'
      s.example 'rendering_and_color'
      s.example 'text_box_extensions'
    end

    p.section 'External Fonts' do |s|
      s.example 'single_usage'
      s.example 'registering_families'
    end

    p.section 'Multilingualization' do |s|
      s.example 'utf8'
      s.example 'line_wrapping'
      s.example 'right_to_left_text'
      s.example 'fallback_fonts'
      s.example 'win_ansi_charset'
    end

    p.intro do
      prose <<-TEXT
        This is probably the feature people will use the most. There is no
        shortage of options when it comes to text. You'll be hard pressed to
        find a use case that is not covered by one of the text methods and
        configurable options.

        The examples show:
      TEXT

      list(
        'Text that flows from page to page automatically starting new pages when necessary',
        'How to use text boxes and place them on specific positions',
        'What to do when a text box is too small to fit its content',
        'Flowing text in columns',
        'How to change the text style configuring font, size, alignment and many other settings',
        'How to style specific portions of a text with inline styling and formatted text',
        'How to define formatted callbacks to reuse common styling definitions',
        'How to use the different rendering modes available for the text methods',
        'How to create your custom text box extensions',
        'How to use external fonts on your pdfs',
        'What happens when rendering text in different languages'
      )
    end
  end
end
