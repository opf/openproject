# frozen_string_literal: true

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

RSpec.describe OpenProject::FileCommandContentTypeDetector do
  it "returns a [mime_type, charset] tuple for a text file" do
    tempfile = Tempfile.new("something")
    tempfile.write("This is a file.")
    tempfile.rewind

    mime, charset = described_class.new(tempfile.path).detect
    expect(mime).to eq("text/plain")
    expect(charset).to be_a(String)

    tempfile.close
  end

  it "returns [sensible_default, nil] when the file command is missing" do
    allow(Open3).to receive(:capture2).and_raise "o noes!"
    expect(described_class.new("/path/to/something").detect).to eq(["application/binary", nil])
  end

  it "returns [sensible_default, nil] on the odd chance that run returns nil" do
    allow(Open3).to receive(:capture2).and_return [nil, 0]
    expect(described_class.new("windows").detect).to eq(["application/binary", nil])
  end

  it "returns [sensible_default, nil] when the file command returns an error code" do
    allow(Open3).to receive(:capture2).and_return ["text/plain", 1]
    expect(described_class.new("windows").detect).to eq(["application/binary", nil])
  end

  it "returns [sensible_default, nil] when the file command returns a type with parentheses" do
    allow(Open3).to receive(:capture2).and_return ["text/plain (with something)", 0]
    expect(described_class.new("windows").detect).to eq(["application/binary", nil])
  end

  it "uses end-of-input delimiter to prevent command injection" do
    allow(Open3).to receive(:capture2)

    described_class.new("--help").detect

    expect(Open3).to have_received(:capture2).with("file", "-b", "--mime", "--", "--help")
  end

  describe "charset parsing edge cases" do
    def detect(raw_output)
      allow(Open3).to receive(:capture2).and_return [raw_output, 0]
      described_class.new("any").detect
    end

    it "extracts charset when followed by an extra unknown parameter" do
      expect(detect("text/plain; charset=utf-8; taste=banana")).to eq(["text/plain", "utf-8"])
    end

    it "only captures the charset token, not trailing content" do
      expect(detect("text/plain; charset=utf-8;extra")).to eq(["text/plain", "utf-8"])
    end

    it "returns nil charset when charset= has no value" do
      expect(detect("text/plain; charset=")).to eq(["text/plain", nil])
    end

    it "ignores unrecognised parameters before charset" do
      expect(detect("text/plain; taste=banana; charset=iso-8859-1")).to eq(["text/plain", "iso-8859-1"])
    end
  end

  describe "charset detection from real fixture files" do
    let(:utf8_fixture)    { Rails.root.join("spec/fixtures/encoding/utf-8.txt").to_s }
    let(:iso8859_fixture) { Rails.root.join("spec/fixtures/encoding/iso-8859-1.txt").to_s }
    let(:png_fixture)     { Rails.root.join("spec/fixtures/files/image.png").to_s }

    it "detects utf-8 charset for a UTF-8 encoded file" do
      expect(described_class.new(utf8_fixture).detect).to eq(["text/plain", "utf-8"])
    end

    it "detects iso-8859-1 charset for an ISO-8859-1 encoded file" do
      expect(described_class.new(iso8859_fixture).detect).to eq(["text/plain", "iso-8859-1"])
    end

    it "returns nil charset for non-text files" do
      mime, charset = described_class.new(png_fixture).detect
      expect(mime).to eq("image/png")
      expect(charset).to be_nil
    end
  end
end
