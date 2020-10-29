# frozen_string_literal: true

require 'spec_helper'

describe Prawn::Document do
  let(:pdf) { create_pdf }

  describe 'When creating annotations' do
    it 'appends annotation to current page' do
      pdf.start_new_page
      pdf.annotate(
        Rect: [0, 0, 10, 10],
        Subtype: :Text,
        Contents: 'Hello world!'
      )
      PDF::Reader.open(StringIO.new(pdf.render)) do |pdf|
        expect(pdf.page(1).attributes[:Annots]).to be_nil
        expect(pdf.page(2).attributes[:Annots].size).to eq(1)
      end
    end

    it 'forces :Type to be :Annot' do
      opts = pdf.annotate(
        Rect: [0, 0, 10, 10],
        Subtype: :Text,
        Contents: 'Hello world!'
      )
      expect(opts[:Type]).to eq(:Annot)
      opts = pdf.annotate(
        Type: :Bogus,
        Rect: [0, 0, 10, 10],
        Subtype: :Text,
        Contents: 'Hello world!'
      )
      expect(opts[:Type]).to eq(:Annot)
    end
  end

  describe 'When creating text annotations' do
    let(:rect) { [0, 0, 10, 10] }
    let(:content) { 'Hello, world!' }

    it 'builds appropriate annotation' do
      opts = pdf.text_annotation(rect, content)
      expect(opts[:Type]).to eq(:Annot)
      expect(opts[:Subtype]).to eq(:Text)
      expect(opts[:Rect]).to eq(rect)
      expect(opts[:Contents]).to eq(content)
    end

    it 'merges extra options' do
      opts = pdf.text_annotation(rect, content, Open: true, Subtype: :Bogus)
      expect(opts[:Subtype]).to eq(:Text)
      expect(opts[:Open]).to eq(true)
    end
  end

  describe 'When creating link annotations' do
    let(:rect) { [0, 0, 10, 10] }
    let(:dest) { 'home' }

    it 'builds appropriate annotation' do
      opts = pdf.link_annotation(rect, Dest: dest)
      expect(opts[:Type]).to eq(:Annot)
      expect(opts[:Subtype]).to eq(:Link)
      expect(opts[:Rect]).to eq(rect)
      expect(opts[:Dest]).to eq(dest)
    end

    it 'merges extra options' do
      opts = pdf.link_annotation(rect, Dest: dest, Subtype: :Bogus)
      expect(opts[:Subtype]).to eq(:Link)
      expect(opts[:Dest]).to eq(dest)
    end
  end
end
