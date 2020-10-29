# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Text::Formatted::Arranger do
  let(:pdf) { create_pdf }
  let(:arranger) { described_class.new pdf }

  describe '#format_array' do
    it 'populates the unconsumed array' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you?' }
      ]

      arranger.format_array = array

      expect(arranger.unconsumed[0]).to eq(text: 'hello ')
      expect(arranger.unconsumed[1]).to eq(text: 'world how ', styles: [:bold])
      expect(arranger.unconsumed[2])
        .to eq(text: 'are', styles: %i[bold italic])
      expect(arranger.unconsumed[3]).to eq(text: ' you?')
    end

    it 'splits newlins into their own elements' do
      array = [
        { text: "\nhello\nworld" }
      ]

      arranger.format_array = array

      expect(arranger.unconsumed[0]).to eq(text: "\n")
      expect(arranger.unconsumed[1]).to eq(text: 'hello')
      expect(arranger.unconsumed[2]).to eq(text: "\n")
      expect(arranger.unconsumed[3]).to eq(text: 'world')
    end
  end

  describe '#preview_next_string' do
    context 'with a formatted array' do
      let(:array) { [{ text: 'hello' }] }

      before do
        arranger.format_array = array
      end

      it 'does not populate the consumed array' do
        arranger.preview_next_string
        expect(arranger.consumed).to eq([])
      end

      it 'returns the text of the next unconsumed hash' do
        expect(arranger.preview_next_string).to eq('hello')
      end

      it 'returns nil if there is no more unconsumed text' do
        arranger.next_string
        expect(arranger.preview_next_string).to be_nil
      end
    end
  end

  describe '#next_string' do
    let(:array) do
      [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you?' }
      ]
    end

    before do
      arranger.format_array = array
    end

    it 'raises RuntimeError if called after a line was finalized' do
      arranger.finalize_line
      expect { arranger.next_string }.to raise_error(RuntimeError)
    end

    it 'populates the conumed array' do
      while arranger.next_string
      end

      expect(arranger.consumed[0]).to eq(text: 'hello ')
      expect(arranger.consumed[1]).to eq(text: 'world how ', styles: [:bold])
      expect(arranger.consumed[2]).to eq(text: 'are', styles: %i[bold italic])
      expect(arranger.consumed[3]).to eq(text: ' you?')
    end

    it 'populates the current_format_state array' do
      arranger.next_string
      expect(arranger.current_format_state).to eq({})

      arranger.next_string
      expect(arranger.current_format_state).to eq(styles: [:bold])

      arranger.next_string
      expect(arranger.current_format_state).to eq(styles: %i[bold italic])

      arranger.next_string
      expect(arranger.current_format_state).to eq({})
    end

    it 'returns the text of the newly consumed hash' do
      expect(arranger.next_string).to eq('hello ')
    end

    it 'returns nil when there are no more unconsumed hashes' do
      4.times do
        arranger.next_string
      end

      expect(arranger.next_string).to be_nil
    end
  end

  describe '#retrieve_fragment' do
    context 'with a formatted array whos text is an empty string' do
      let(:array) do
        [
          { text: "hello\nworld\n\n\nhow are you?" },
          { text: "\n" },
          { text: "\n" },
          { text: "\n" },
          { text: '' },
          { text: 'fine, thanks.' },
          { text: '' },
          { text: "\n" },
          { text: '' }
        ]
      end

      before do
        arranger.format_array = array

        while arranger.next_string
        end

        arranger.finalize_line
      end

      # rubocop: disable Lint/AssignmentInCondition
      it 'never returns a fragment whose text is an empty string' do
        while fragment = arranger.retrieve_fragment
          expect(fragment.text).to_not be_empty
        end
      end
      # rubocop: enable Lint/AssignmentInCondition
    end

    context 'with formatted array' do
      let(:array) do
        [
          { text: 'hello ' },
          { text: 'world how ', styles: [:bold] },
          { text: 'are', styles: %i[bold italic] },
          { text: ' you?' }
        ]
      end

      before do
        arranger.format_array = array
      end

      describe 'after all strings have been consumed' do
        before do
          while arranger.next_string
          end
        end

        it 'raises RuntimeError an error if not finalized' do
          expect { arranger.retrieve_fragment }.to raise_error(RuntimeError)
        end

        describe 'and finalized' do
          before do
            arranger.finalize_line
          end

          it 'returns the consumed fragments in order of consumption' do
            expect(arranger.retrieve_fragment.text).to eq('hello ')
            expect(arranger.retrieve_fragment.text).to eq('world how ')
            expect(arranger.retrieve_fragment.text).to eq('are')
            expect(arranger.retrieve_fragment.text).to eq(' you?')
          end

          it 'does not alter the current font style' do
            arranger.retrieve_fragment
            expect(arranger.current_format_state[:styles]).to be_nil
          end
        end
      end
    end
  end

  describe '#update_last_string' do
    it 'updates the last retrieved string with what actually fit on the line '\
       'and the list of unconsumed with what did not' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?', styles: %i[bold italic] }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.update_last_string(' you', ' now?', nil)
      expect(arranger.consumed[3]).to eq(
        text: ' you',
        styles: %i[bold italic]
      )
      expect(arranger.unconsumed).to eq([
        { text: ' now?', styles: %i[bold italic] }
      ])
    end

    it 'sets the format state to the previously processed fragment' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      3.times { arranger.next_string }
      expect(arranger.current_format_state).to eq(styles: %i[bold italic])
      arranger.update_last_string('', 'are', '-')
      expect(arranger.current_format_state).to eq(styles: [:bold])
    end

    context 'when the entire string was used' do
      it 'does not push empty string onto unconsumed' do
        array = [
          { text: 'hello ' },
          { text: 'world how ', styles: [:bold] },
          { text: 'are', styles: %i[bold italic] },
          { text: ' you now?' }
        ]
        arranger.format_array = array
        while arranger.next_string
        end
        arranger.update_last_string(' you now?', '', nil)
        expect(arranger.unconsumed).to eq([])
      end
    end
  end

  describe '#space_count' do
    before do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you?' }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
    end

    it 'raise_errors an error if called before finalize_line was called' do
      expect do
        arranger.space_count
      end.to raise_error(RuntimeError)
    end

    it 'returns the total number of spaces in all fragments' do
      arranger.finalize_line
      expect(arranger.space_count).to eq(4)
    end
  end

  describe '#finalize_line' do
    it 'makes it so that all trailing white space fragments exclude '\
       'trailing white space' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: '   ', styles: %i[bold italic] }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.finalize_line
      expect(arranger.fragments.length).to eq(3)

      fragment = arranger.retrieve_fragment
      expect(fragment.text).to eq('hello ')

      fragment = arranger.retrieve_fragment
      expect(fragment.text).to eq('world how')

      fragment = arranger.retrieve_fragment
      expect(fragment.text).to eq('')
    end
  end

  describe '#line_width' do
    before do
      array = [
        { text: 'hello ' },
        { text: 'world', styles: [:bold] }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
    end

    it 'raise_errors an error if called before finalize_line was called' do
      expect do
        arranger.line_width
      end.to raise_error(RuntimeError)
    end

    it 'returns the width of the complete line' do
      arranger.finalize_line
      expect(arranger.line_width).to be > 0
    end
  end

  describe '#line_width with character_spacing > 0' do
    it 'returns a width greater than a line without a character_spacing' do
      array = [
        { text: 'hello ' },
        { text: 'world', styles: [:bold] }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.finalize_line

      base_line_width = arranger.line_width

      array = [
        { text: 'hello ' },
        { text: 'world', styles: [:bold], character_spacing: 7 }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.finalize_line
      expect(arranger.line_width).to be > base_line_width
    end
  end

  describe '#line' do
    before do
      array = [
        { text: 'hello ' },
        { text: 'world', styles: [:bold] }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
    end

    it 'raise_errors an error if called before finalize_line was called' do
      expect do
        arranger.line
      end.to raise_error(RuntimeError)
    end

    it 'returns the complete line' do
      arranger.finalize_line
      expect(arranger.line).to eq('hello world')
    end
  end

  describe '#unconsumed' do
    it 'returns the original array if nothing was consumed' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      expect(arranger.unconsumed).to eq(array)
    end

    it 'returns an empty array if everything was consumed' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      expect(arranger.unconsumed).to eq([])
    end
  end

  describe '#finished' do
    it 'be_falses if anything was not printed' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.update_last_string(' you', 'now?', nil)
      expect(arranger).to_not be_finished
    end

    it 'be_falses if everything was printed' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      expect(arranger).to be_finished
    end
  end

  describe '#max_line_height' do
    it 'is the height of the maximum consumed fragment' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic], size: 28 },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.finalize_line
      expect(arranger.max_line_height).to be_within(0.0001).of(33.32)
    end
  end

  describe '#repack_unretrieved' do
    it 'restores part of the original string' do
      array = [
        { text: 'hello ' },
        { text: 'world how ', styles: [:bold] },
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ]
      arranger.format_array = array
      while arranger.next_string
      end
      arranger.finalize_line
      arranger.retrieve_fragment
      arranger.retrieve_fragment
      arranger.repack_unretrieved
      expect(arranger.unconsumed).to eq([
        { text: 'are', styles: %i[bold italic] },
        { text: ' you now?' }
      ])
    end
  end
end
