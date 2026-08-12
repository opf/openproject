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

require "spec_helper"

RSpec.describe Saml::MetadataFetcher do
  let(:url) { "https://example.com/metadata" }
  let(:response) { instance_double(Net::HTTPSuccess) }

  before do
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(OpenProject::SsrfProtection).to receive(:get).and_yield(response)
  end

  describe ".fetch" do
    context "with a successful response" do
      before do
        allow(response).to receive(:read_body).and_yield("<xml/>")
      end

      it "yields a file with the response body rewound to the start" do
        described_class.fetch(url) do |file|
          expect(file).to be_a(File)
          expect(file.pos).to eq(0)
          expect(file.read).to eq("<xml/>")
        end
      end

      it "removes the tempfile after the block" do
        path = nil
        described_class.fetch(url) do |file|
          path = file.path
          expect(File.exist?(path)).to be(true)
        end
        expect(File.exist?(path)).to be(false)
      end
    end

    context "when the response is not successful" do
      let(:response) { instance_double(Net::HTTPNotFound, code: "404", message: "Not Found") }

      before do
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(OpenProject::SsrfProtection).to receive(:get).and_yield(response)
      end

      it "raises HttpError without yielding" do
        yielded = false
        expect do
          described_class.fetch(url) { yielded = true }
        end.to raise_error(OneLogin::RubySaml::HttpError, /404/)
        expect(yielded).to be(false)
      end
    end

    context "when the response body exceeds MAX_SIZE" do
      before do
        allow(response).to receive(:read_body).and_yield("x" * (Saml::MetadataDocument::MAX_SIZE + 1))
      end

      it "raises MetadataTooLargeError without yielding" do
        yielded = false
        expect do
          described_class.fetch(url) { yielded = true }
        end.to raise_error(Saml::MetadataDocument::MetadataTooLargeError)
        expect(yielded).to be(false)
      end
    end
  end
end
