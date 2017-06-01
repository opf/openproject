#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe RedCloth3 do
  describe '#to_html', 'with one full heading tree starting at h1' do
    before(:each) do
      @text = <<-RAW

      h1#. Title

      Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

      h2#. Subtitle

      Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

      h2#. Subtitle

      h3#. Subsubtitle

      h2#. Subtitle

      h1#. Another title

      h2#. Subtitle

      h2#. Subtitle

      RAW
    end

    it 'should numerate as specified' do
      expected = '<h1>1. Title</h1>' +
                 '<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.</p>' +
                 '<h2>1.1. Subtitle</h2>' +
                 '<p>Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.</p>' +
                 '<h2>1.2. Subtitle</h2>' +
                 '<h3>1.2.1. Subsubtitle</h3>' +
                 '<h2>1.3. Subtitle</h2>' +
                 '<h1>2. Another title</h1>' +
                 '<h2>2.1. Subtitle</h2>' +
                 '<h2>2.2. Subtitle</h2>'

      expect(RedCloth3.new(@text).to_html.gsub("\n", '').gsub("\t", '')).to eq(expected)
    end
  end

  describe '#to_html', 'with one heading tree starting at h2' do
    before(:each) do
      @text = <<-RAW

      h1. Title

      Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

      h2#. Subtitle

      Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

      h2#. Subtitle

      h3#. Subsubtitle

      h2#. Subtitle

      h1. Another title

      h2. Subtitle

      h2. Subtitle

      RAW
    end

    it 'should numerate as specified' do
      expected = '<h1>Title</h1>' +
                 '<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.</p>' +
                 '<h2>1. Subtitle</h2>' +
                 '<p>Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.</p>' +
                 '<h2>2. Subtitle</h2>' +
                 '<h3>2.1. Subsubtitle</h3>' +
                 '<h2>3. Subtitle</h2>' +
                 '<h1>Another title</h1>' +
                 '<h2>Subtitle</h2>' +
                 '<h2>Subtitle</h2>'

      expect(RedCloth3.new(@text).to_html.gsub("\n", '').gsub("\t", '')).to eq(expected)
    end
  end

  describe '#to_html', 'with two heading trees starting at h2' do
    before(:each) do
      @text = <<-RAW

        h1. Title

        Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

        h2#. Subtitle

        Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

        h2#. Subtitle

        h3#. Subsubtitle

        h2#. Subtitle

        h1. Another title

        h2#. Subtitle

        h2#. Subtitle

        RAW
    end

    it 'should numerate as specified' do
      expected = '<h1>Title</h1>' +
                 '<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.</p>' +
                 '<h2>1. Subtitle</h2>' +
                 '<p>Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.</p>' +
                 '<h2>2. Subtitle</h2>' +
                 '<h3>2.1. Subsubtitle</h3>' +
                 '<h2>3. Subtitle</h2>' +
                 '<h1>Another title</h1>' +
                 '<h2>1. Subtitle</h2>' +
                 '<h2>2. Subtitle</h2>'

      expect(RedCloth3.new(@text).to_html.gsub("\n", '').gsub("\t", '')).to eq(expected)
    end
  end

  describe '#to_html', 'with one heading tree starting at h2 and right after it one starting at h1' do
    before(:each) do
      @text = <<-RAW

          h1. Title

          Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.

          h2#. Subtitle

          Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.

          h2#. Subtitle

          h3#. Subsubtitle

          h2#. Subtitle

          h1#. Another title

          h2#. Subtitle

          h2#. Subtitle

          RAW
    end

    it 'should numerate as specified' do
      expected = '<h1>Title</h1>' +
                 '<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.</p>' +
                 '<h2>1. Subtitle</h2>' +
                 '<p>Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.</p>' +
                 '<h2>2. Subtitle</h2>' +
                 '<h3>2.1. Subsubtitle</h3>' +
                 '<h2>3. Subtitle</h2>' +
                 '<h1>1. Another title</h1>' +
                 '<h2>1.1. Subtitle</h2>' +
                 '<h2>1.2. Subtitle</h2>'

      expect(RedCloth3.new(@text).to_html.gsub("\n", '').gsub("\t", '')).to eq(expected)
    end
  end
end
