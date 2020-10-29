# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text::Formatted::Parser do
  describe '#format' do
    it 'handles sup' do
      string = '<sup>superscript</sup>'
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'superscript',
        styles: [:superscript],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles sub' do
      string = '<sub>subscript</sub>'
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'subscript',
        styles: [:subscript],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles rgb' do
      string = "<color rgb='#ff0000'>red text</color>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'red text',
        styles: [],
        color: 'ff0000',
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it '# should be optional in rgb' do
      string = "<color rgb='ff0000'>red text</color>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'red text',
        styles: [],
        color: 'ff0000',
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles cmyk' do
      string = "<color c='0' m='100' y='0' k='0'>magenta text</color>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'magenta text',
        styles: [],
        color: [0, 100, 0, 0],
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles fonts' do
      string = "<font name='Courier'>Courier text</font>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'Courier text',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: 'Courier',
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles size' do
      string = "<font size='14'>14 point text</font>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: '14 point text',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: 14,
        character_spacing: nil
      )
    end

    it 'handles character_spacing' do
      string = "<font character_spacing='2.5'>extra character spacing</font>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'extra character spacing',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: 2.5
      )
    end

    it 'handles links' do
      string = "<link href='http://example.com'>external link</link>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'external link',
        styles: [],
        color: nil,
        link: 'http://example.com',
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles local links' do
      string = "<link local='/home/example/foo.bar'>local link</link>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'local link',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: '/home/example/foo.bar',
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles anchors' do
      string = "<link anchor='ToC'>internal link</link>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: 'internal link',
        styles: [],
        color: nil,
        link: nil,
        anchor: 'ToC',
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles higher order characters properly' do
      string = "<b>©\n©</b>"
      array = described_class.format(string)
      expect(array[0]).to eq(
        text: '©',
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[1]).to eq(
        text: "\n",
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[2]).to eq(
        text: '©',
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'converts &lt; &gt;, and &amp; to <, >, and &, respectively' do
      string = 'hello <b>&lt;, &gt;, and &amp;</b>'
      array = described_class.format(string)
      expect(array[1]).to eq(
        text: '<, >, and &',
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'handles double qoutes around tag attributes' do
      string = 'some <font size="14">sized</font> text'
      array = described_class.format(string)
      expect(array[1]).to eq(
        text: 'sized',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: 14,
        character_spacing: nil
      )
    end

    it 'handles single qoutes around tag attributes' do
      string = "some <font size='14'>sized</font> text"
      array = described_class.format(string)
      expect(array[1]).to eq(
        text: 'sized',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: 14,
        character_spacing: nil
      )
    end

    it 'constructs a formatted text array from a string' do
      string = "hello <b>world\nhow <i>are</i></b> you?"
      array = described_class.format(string)

      expect(array[0]).to eq(
        text: 'hello ',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[1]).to eq(
        text: 'world',
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[2]).to eq(
        text: "\n",
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[3]).to eq(
        text: 'how ',
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[4]).to eq(
        text: 'are',
        styles: %i[bold italic],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[5]).to eq(
        text: ' you?',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'accepts <strong> as an alternative to <b>' do
      string = '<strong>bold</strong> not bold'
      array = described_class.format(string)

      expect(array[0]).to eq(
        text: 'bold',
        styles: [:bold],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[1]).to eq(
        text: ' not bold',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'accepts <em> as an alternative to <i>' do
      string = '<em>italic</em> not italic'
      array = described_class.format(string)

      expect(array[0]).to eq(
        text: 'italic',
        styles: [:italic],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[1]).to eq(
        text: ' not italic',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'accepts <a> as an alternative to <link>' do
      string = "<a href='http://example.com'>link</a> not a link"
      array = described_class.format(string)

      expect(array[0]).to eq(
        text: 'link',
        styles: [],
        color: nil,
        link: 'http://example.com',
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
      expect(array[1]).to eq(
        text: ' not a link',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      )
    end

    it 'turns <br>, <br/> into newline' do
      array = described_class.format('hello<br>big<br/>world')
      expect(array.map { |frag| frag[:text] }.join).to eq("hello\nbig\nworld")
    end
  end

  describe '#to_string' do
    it 'handles sup' do
      string = '<sup>superscript</sup>'
      array = [{
        text: 'superscript',
        styles: [:superscript],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles sub' do
      string = '<sub>subscript</sub>'
      array = [{
        text: 'subscript',
        styles: [:subscript],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles rgb' do
      string = "<color rgb='ff0000'>red text</color>"
      array = [{
        text: 'red text',
        styles: [],
        color: 'ff0000',
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles cmyk' do
      string = "<color c='0' m='100' y='0' k='0'>magenta text</color>"
      array = [{
        text: 'magenta text',
        styles: [],
        color: [0, 100, 0, 0],
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles fonts' do
      string = "<font name='Courier'>Courier text</font>"
      array = [{
        text: 'Courier text',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: 'Courier',
        size: nil,
        character_spacing: nil
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles size' do
      string = "<font size='14'>14 point text</font>"
      array = [{
        text: '14 point text',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: 14,
        character_spacing: nil
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles character spacing' do
      string =
        "<font character_spacing='2.5'>2.5 extra character spacing</font>"
      array = [{
        text: '2.5 extra character spacing',
        styles: [],
        color: nil,
        link: nil,
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: 2.5
      }]
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles links' do
      array = [{
        text: 'external link',
        styles: [],
        color: nil,
        link: 'http://example.com',
        anchor: nil,
        local: nil,
        font: nil,
        size: nil,
        character_spacing: nil
      }]
      string = "<link href='http://example.com'>external link</link>"
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'handles anchors' do
      array = [{
        text: 'internal link',
        styles: [],
        color: nil,
        link: nil,
        anchor: 'ToC',
        font: nil,
        size: nil,
        character_spacing: nil
      }]
      string = "<link anchor='ToC'>internal link</link>"
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'converts <, >, and & to &lt; &gt;, and &amp;, respectively' do
      array = [
        {
          text: 'hello ',
          styles: [],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        },
        {
          text: '<, >, and &',
          styles: [:bold],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        }
      ]
      string = 'hello <b>&lt;, &gt;, and &amp;</b>'
      expect(described_class.to_string(array)).to eq(string)
    end

    it 'constructs an HTML-esque string from a formatted text array' do
      array = [
        {
          text: 'hello ',
          styles: [],
          color: nil,
          link: nil,
          font: nil,
          size: 14,
          character_spacing: nil
        },
        {
          text: 'world',
          styles: [:bold],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        },
        {
          text: "\n",
          styles: [:bold],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        },
        {
          text: 'how ',
          styles: [:bold],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        },
        {
          text: 'are',
          styles: %i[bold italic],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        },
        {
          text: ' you?',
          styles: [],
          color: nil,
          link: nil,
          font: nil,
          size: nil,
          character_spacing: nil
        }
      ]
      string = "<font size='14'>hello </font><b>world</b><b>\n"\
        '</b><b>how </b><b><i>are</i></b> you?'
      expect(described_class.to_string(array)).to eq(string)
    end
  end

  describe '#array_paragraphs' do
    it 'groups fragments separated by newlines' do
      array = [
        { text: "\nhello\nworld" },
        { text: "\n\n" },
        { text: 'how' },
        { text: 'are' },
        { text: 'you' }
      ]
      target = [
        [{ text: "\n" }],
        [{ text: 'hello' }],
        [{ text: 'world' }],
        [{ text: "\n" }],
        [
          { text: 'how' },
          { text: 'are' },
          { text: 'you' }
        ]
      ]
      expect(described_class.array_paragraphs(array)).to eq(target)
    end

    it 'works properly if ending in an empty paragraph' do
      array = [{ text: "\nhello\nworld\n" }]
      target = [
        [{ text: "\n" }],
        [{ text: 'hello' }],
        [{ text: 'world' }]
      ]
      expect(described_class.array_paragraphs(array)).to eq(target)
    end
  end
end
