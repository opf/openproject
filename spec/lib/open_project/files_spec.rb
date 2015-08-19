#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# This file is mostly based on source code of thoughbot's paperclip gem
#
#   https://github.com/thoughtbot/paperclip
#
# which is released under:
#
# The MIT License
#
# Copyright (c) 2008-2014 Jon Yurek and thoughtbot, inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'spec_helper'

describe OpenProject::Files do
  describe 'build_uploaded_file' do
    let(:original_filename) { 'test.png' }
    let(:content_type) { 'image/png' }
    let(:file) {
      OpenProject::Files.create_temp_file(name: original_filename)
    }

    subject { OpenProject::Files.build_uploaded_file(file, content_type) }

    it 'has the original file name' do
      expect(subject.original_filename).to eql(original_filename)
    end

    it 'has the given content type' do
      expect(subject.content_type).to eql(content_type)
    end

    context 'with custom file name' do
      let(:file_name) { 'my-custom-filename.png' }

      subject { OpenProject::Files.build_uploaded_file(file, content_type, file_name: file_name) }

      it 'has the custom file name' do
        expect(subject.original_filename).to eql(file_name)
      end
    end
  end

  describe 'create_uploaded_file' do
    context 'without parameters' do
      let(:file) { OpenProject::Files.create_uploaded_file }

      it 'creates a file with the default name "test.txt"' do
        expect(file.original_filename).to eq 'test.txt'
      end

      it 'creates distinct files even with identical names' do
        file_2 = OpenProject::Files.create_uploaded_file

        expect(file.original_filename).to eq file_2.original_filename
        expect(file.path).not_to eq file_2.path
      end

      it 'writes some default content "test content"' do
        expect(file.read).to eq 'test content'
      end

      it 'set default content type "text/plain"' do
        expect(file.content_type).to eq 'text/plain'
      end
    end

    context 'with a custom name, content and content type' do
      let(:name)         { 'foo.jpg' }
      let(:content)      { 'not-really-a-jpg' }
      let(:content_type) { 'image/jpeg' }

      let(:file) do
        OpenProject::Files.create_uploaded_file name: name,
                                                content: content,
                                                content_type: content_type
      end

      it 'creates a file called "foo.jpg"' do
        expect(file.original_filename).to eq name
      end

      it 'writes the custom content' do
        expect(file.read).to eq content
      end

      it 'sets the content type to "image/jpeg"' do
        expect(file.content_type).to eq content_type
      end
    end

    context 'with binary content' do
      let(:content) { "\xD1\x9B\x86".b }
      let(:binary)  { false }
      let(:file)    { OpenProject::Files.create_uploaded_file content: content, binary: binary }

      it 'fails when the content is not marked as binary' do
        expect { file }.to raise_error(Encoding::UndefinedConversionError)
      end

      context 'with the file denoted as binary' do
        let(:binary) { true }

        it 'succeeds' do
          expect(file.read).to eq content
        end
      end
    end
  end
end
