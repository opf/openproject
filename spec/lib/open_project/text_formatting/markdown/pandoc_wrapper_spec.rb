#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::TextFormatting::Formats::Markdown::PandocWrapper do
  let(:subject) { described_class.new }
  let(:output_formats) { "gfm\n foo\n" }

  before do
    allow(subject).to receive(:read_usage_string).and_return(usage_string)
    allow(subject).to receive(:read_output_formats).and_return(output_formats)
  end

  describe 'gfm mode' do
    let(:usage_string) { 'does not matter' }
    context 'when gfm exists' do
      it 'uses gfm format' do
        expect(subject.output_format).to eq 'gfm'
      end
    end

    context 'when gfm does not exist' do
      let(:output_formats) { "bar\n foo\n" }

      it 'uses the legacy format' do
        expect(subject.output_format).to eq 'markdown_github'
      end
    end

    context 'list-output-formats does not exist' do
      let(:usage_string) { 'does not matter' }

      before do
        allow(subject).to receive(:run_pandoc!).and_raise 'unrecognized option `--list-output-formats`'
        allow(subject).to receive(:read_output_formats).and_call_original
      end

      it 'still falls back to markdown_github' do
        expect(subject.output_format).to eq 'markdown_github'
      end
    end
  end

  describe 'wrap mode' do
    context 'when wrap=preserve exists' do
      let(:usage_string) do
        <<~EOS
                        --list-output-formats                           
                        --list-highlight-languages                      
                        --list-highlight-styles                         
                        --wrap=auto|none|preserve
  -v                    --version                                       
  -h                    --help
        EOS
      end

      it do
        expect(subject.wrap_mode).to eq('--wrap=preserve')
      end
    end

    context 'when only no-wrap exists' do
      let(:usage_string) do
        <<~EOS
                        --list-output-formats                           
                        --list-highlight-languages                      
                        --list-highlight-styles                         
                        --no-wrap
  -v                    --version                                       
  -h                    --help
        EOS
      end
      it do
        expect(subject.wrap_mode).to eq('--no-wrap')
      end
    end

    context 'when neither exists' do
      let(:usage_string) { 'wat?' }
      it do
        expect { subject.wrap_mode }.to raise_error 'Your pandoc version has neither --no-wrap nor --wrap=preserve. Please install a recent version of pandoc.'
      end
    end
  end
end
