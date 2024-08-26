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

RSpec.describe OpenProject::MimeType do
  describe "#of" do
    to_test = { "test.unk" => nil,
                "test.txt" => "text/plain",
                "test.c" => "text/x-c" }
    to_test.each do |name, expected|
      it do
        expect(described_class.of(name)).to eq expected
      end
    end
  end

  describe "#css_class_of" do
    to_test = { "test.unk" => nil,
                "test.txt" => "text-plain",
                "test.c" => "text-x-c" }
    to_test.each do |name, expected|
      it do
        expect(described_class.css_class_of(name)).to eq expected
      end
    end
  end

  describe "#main_mimetype_of" do
    to_test = { "test.unk" => nil,
                "test.txt" => "text",
                "test.c" => "text" }
    to_test.each do |name, expected|
      it do
        expect(described_class.main_mimetype_of(name)).to eq expected
      end
    end
  end

  describe "#is_type?" do
    to_test = { ["text", "test.unk"] => false,
                ["text", "test.txt"] => true,
                ["text", "test.c"] => true }

    to_test.each do |args, expected|
      it do
        expect(described_class.is_type?(*args)).to eq expected
      end
    end
  end

  it "equals the main type for the narrow type" do
    expect(described_class.narrow_type("rubyfile.rb", "text/plain")).to eq "text/x-ruby"
  end

  it "uses original type if main type differs" do
    expect(described_class.narrow_type("rubyfile.rb", "application/zip")).to eq "application/zip"
  end
end
