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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Import::CSV::FormatSniffer do
  def fixture(name)
    Rails.root.join("spec/fixtures/csv_import", name)
  end

  def with_file(bytes)
    Tempfile.create(%w[import .csv], binmode: true) do |file|
      file.write(bytes)
      file.flush
      yield file
    end
  end

  describe "a file that could be a UTF-8 CSV" do
    it "accepts a plain CSV" do
      expect(described_class.call(fixture("work_packages.csv"))).to be_success
    end

    it "accepts non-ASCII subjects" do
      with_file("Subject\nStraßenbahnhaltestelle prüfen\n") do |file|
        expect(described_class.call(file)).to be_success
      end
    end

    it "accepts a CSV of plain ASCII, which is reported as us-ascii rather than utf-8" do
      with_file("Subject\nBuild\n") do |file|
        expect(described_class.new(file).detected.last).to eq("us-ascii")
        expect(described_class.call(file)).to be_success
      end
    end

    it "accepts a CSV carrying a UTF-8 BOM" do
      with_file("\xEF\xBB\xBFSubject\nBuild\n".b) do |file|
        expect(described_class.call(file)).to be_success
      end
    end

    it "accepts an empty file, which the parser rejects with a better message" do
      with_file("") do |file|
        expect(described_class.call(file)).to be_success
      end
    end

    it "accepts a UTF-16 export, as Excel on macOS writes it" do
      expect(described_class.call(fixture("utf16le.csv"))).to be_success
      expect(described_class.call(fixture("utf16be.csv"))).to be_success
    end

    it "refuses UTF-16 without a byte order mark, which nothing can identify" do
      with_file("Subject\nBuild it\n".encode(Encoding::UTF_16LE).b) do |file|
        expect(described_class.call(file).result).to eq(:unknown)
      end
    end

    it "accepts a text file that is not a CSV, which is the parser's job to reject" do
      with_file("just some prose, no columns at all\n") do |file|
        expect(described_class.call(file)).to be_success
      end
    end
  end

  describe "a file that cannot be a UTF-8 CSV" do
    it "rejects a binary file, whatever it happens to be" do
      result = described_class.call(Rails.root.join("spec/fixtures/files/image.png"))

      expect(result).to be_failure
      expect(result.result).to eq(:unknown)
      expect(result.message).to start_with("This is not a UTF-8 CSV file")
    end

    it "rejects a NUL byte, which makes the file binary" do
      with_file("Subject\nBu\x00ild\n".b) do |file|
        expect(described_class.call(file).result).to eq(:unknown)
      end
    end
  end

  describe "a CSV in the wrong encoding" do
    it "names ISO-8859-1" do
      with_file("Subject\nStra\xDFe\n".b) do |file|
        expect(described_class.call(file).message).to include("ISO-8859-1")
      end
    end

    it "reports the same verdict as any other unreadable file" do
      with_file("Subject\nStra\xDFe\n".b) do |file|
        expect(described_class.call(file).result).to eq(:unknown)
      end
    end
  end

  describe "what it is handed" do
    it "takes an uploaded file" do
      upload = Rack::Test::UploadedFile.new(fixture("work_packages.csv"), "text/csv")

      expect(described_class.call(upload)).to be_success
    end

    it "takes a path" do
      expect(described_class.call(fixture("work_packages.csv").to_s)).to be_success
    end
  end

  describe "when the file command cannot be run" do
    before do
      allow(OpenProject::ContentTypeDetector)
        .to receive(:new).and_return(instance_double(OpenProject::ContentTypeDetector,
                                                     detect_with_charset: ["application/binary", nil]))
    end

    it "refuses the upload rather than letting an unreadable file through" do
      expect(described_class.call(fixture("work_packages.csv")).result).to eq(:unknown)
    end
  end
end
