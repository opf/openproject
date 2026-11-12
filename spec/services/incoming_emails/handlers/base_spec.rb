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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe IncomingEmails::Handlers::Base do
  let(:user) { build_stubbed(:user) }
  let(:reference) { nil }
  let(:options) { {} }
  let(:plain_text_body) { "Test body" }

  subject do
    described_class.new(nil, user:, reference:, plain_text_body:, options:)
  end

  describe "#cleanup_body" do
    let(:plain_text_body) do
      "Subject:foo\nDescription:bar\n" \
        ">>> myserver.example.org 2016-01-27 15:56 >>>\n... (Email-Body) ..."
    end

    context "with regex delimiter" do
      before do
        allow(Setting).to receive(:mail_handler_body_delimiter_regex).and_return(">>>.+?>>>.*")
      end

      it "removes the irrelevant lines" do
        expect(subject.cleaned_up_text_body).to eq("Subject:foo\nDescription:bar")
      end
    end

    context "with string delimiters" do
      before do
        allow(Setting).to receive_messages(mail_handler_body_delimiters: "---", mail_handler_body_delimiter_regex: "")
      end

      it "removes content after delimiter" do
        body = "Before delimiter\n---\nAfter delimiter"
        result = subject.send(:cleanup_body, body)
        expect(result).to eq("Before delimiter")
      end
    end
  end

  describe "#get_keyword" do
    let(:plain_text_body) { "Project: test\nStatus: Open\nSome content here".dup }
    let(:options) { { allow_override: [:project], issue: {} } }

    it "extracts keyword from body" do
      result = subject.send(:get_keyword, :project)
      expect(result).to eq("test")
    end

    it "returns nil for non-existent keyword" do
      result = subject.send(:get_keyword, :nonexistent)
      expect(result).to be_nil
    end

    it "respects allow_override option" do
      result = subject.send(:get_keyword, :status)
      expect(result).to be_nil # status not in allow_override
    end
  end

  describe "#extract_keyword!" do
    it "extracts and removes keyword from text" do
      text = "Project: test\nStatus: Open\nSome content here".dup
      result = subject.send(:extract_keyword!, text, :project, nil)
      expect(result).to eq("test")
      expect(text).not_to include("Project: test")
    end

    it "handles case insensitive matching" do
      text = "PROJECT: test\nContent".dup
      result = subject.send(:extract_keyword!, text, :project, nil)
      expect(result).to eq("test")
    end
  end

  describe "#human_attr_translations" do
    let(:user) { build_stubbed(:user, language: "en") }

    it "returns array of attribute translations" do
      result = subject.send(:human_attr_translations, :project)
      expect(result).to include("project", "Project")
    end

    it "includes translations for user language" do
      allow(Setting).to receive(:default_language).and_return("en")
      result = subject.send(:human_attr_translations, :project)
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
    end
  end

  describe "#ignored_filename?" do
    before do
      allow(Setting).to receive(:mail_handler_ignore_filenames).and_return("signature.asc\n*.tmp")
    end

    it "returns true for ignored filenames" do
      expect(subject.send(:ignored_filename?, "signature.asc")).to be_truthy
    end

    it "returns false for non-ignored filenames" do
      expect(subject.send(:ignored_filename?, "document.pdf")).to be_falsey
    end
  end

  describe "#lookup_case_insensitive_key" do
    let(:scope) { class_double(Status) }
    let(:status) { build_stubbed(:status) }
    let(:options) { { allow_override: [:status], issue: {} } }
    let(:plain_text_body) { "Status: resolved".dup }

    before do
      allow(scope).to receive(:find_by).with("lower(name) = ?", "resolved").and_return(status)
    end

    it "finds record case insensitively" do
      result = subject.send(:lookup_case_insensitive_key, scope, :status)
      expect(result).to eq(status.id)
    end

    it "returns nil when keyword not found" do
      allow(scope).to receive(:find_by).and_return(nil)
      result = subject.send(:lookup_case_insensitive_key, scope, :status)
      expect(result).to be_nil
    end
  end
end
