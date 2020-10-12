#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

describe OpenProject::FileCommandContentTypeDetector do
  it 'returns a content type based on the content of the file' do
    tempfile = Tempfile.new('something')
    tempfile.write('This is a file.')
    tempfile.rewind

    assert_equal 'text/plain', OpenProject::FileCommandContentTypeDetector.new(tempfile.path).detect

    tempfile.close
  end

  it 'returns a sensible default when the file command is missing' do
    allow(::Open3).to receive(:capture2).and_raise 'o noes!'
    @filename = '/path/to/something'
    assert_equal 'application/binary',
                 OpenProject::FileCommandContentTypeDetector.new(@filename).detect
  end

  it 'returns a sensible default on the odd chance that run returns nil' do
    allow(::Open3).to receive(:capture2).and_return [nil, 0]
    assert_equal 'application/binary',
                 OpenProject::FileCommandContentTypeDetector.new('windows').detect
  end
end
