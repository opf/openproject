#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
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

require "spec_helper"

RSpec.describe OpenProject::ContentTypeDetector do
  it "gives a sensible default when the name is empty" do
    expect(OpenProject::ContentTypeDetector.new("").detect).to eq("application/binary")
  end

  it "returns the empty content type when the file is empty" do
    tempfile = Tempfile.new("empty")
    expect(OpenProject::ContentTypeDetector.new(tempfile.path).detect).to eq("inode/x-empty")
    tempfile.close
  end

  it "returns content type of file if it is an acceptable type" do
    allow(MIME::Types).to receive(:type_for).and_return([MIME::Type.new("application/mp4"), MIME::Type.new("video/mp4"),
                                                         MIME::Type.new("audio/mp4")])
    allow(Open3).to receive(:capture2).and_return(["video/mp4", 0])
    @filename = "my_file.mp4"
    expect(OpenProject::ContentTypeDetector.new(@filename).detect).to eq("video/mp4")
  end

  it "returns the default when exitcode > 0" do
    allow(MIME::Types).to receive(:type_for).and_return([MIME::Type.new("application/mp4"), MIME::Type.new("video/mp4"),
                                                         MIME::Type.new("audio/mp4")])
    allow(Open3).to receive(:capture2).and_return(["", 1])
    @filename = "my_file.mp4"
    expect(OpenProject::ContentTypeDetector.new(@filename).detect).to eq("application/binary")
  end

  it "finds the right type in the list via the file command" do
    @filename = "#{Dir.tmpdir}/something.hahalolnotreal"
    File.open(@filename, "w+") do |file|
      file.puts "This is a text file."
      file.rewind
      expect(OpenProject::ContentTypeDetector.new(file.path).detect).to eq("text/plain")
    end
    FileUtils.rm @filename
  end

  it "returns a sensible default if something is wrong, like the file is gone" do
    @filename = "/path/to/nothing"
    expect(OpenProject::ContentTypeDetector.new(@filename).detect).to eq("application/binary")
  end

  it "returns a sensible default when the file command is missing" do
    allow(Open3).to receive(:capture2).and_raise "o noes!"
    @filename = "/path/to/something"
    expect(OpenProject::ContentTypeDetector.new(@filename).detect).to eq("application/binary")
  end
end
