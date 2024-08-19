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

RSpec.describe Source::SeedDataLoader do
  let(:seed_name) { "standard" }

  subject(:loader) { described_class.new(seed_name:) }

  def seed_file_double(name:, raw_content:)
    instance_double(
      Source::SeedFile,
      name:,
      raw_content:
    )
  end

  describe "#raw_content" do
    it "merges the data from seed files matching the given seed name" do
      allow(Source::SeedFile).to receive(:all).and_return(
        [
          seed_file_double(name: seed_name,
                           raw_content: {
                             "data_from_file1" => "hello"
                           }),
          seed_file_double(name: seed_name,
                           raw_content: {
                             "data_from_file2" => "world"
                           })
        ]
      )

      expect(loader.translated_seed_files_content).to eq(
        {
          "data_from_file1" => "hello",
          "data_from_file2" => "world"
        }
      )
    end

    it "merges also the data from all common seed files regardless of the given seed name" do
      allow(Source::SeedFile).to receive(:all).and_return(
        [
          seed_file_double(name: seed_name,
                           raw_content: {
                             "data_from_file1" => "hello"
                           }),
          seed_file_double(name: "common",
                           raw_content: {
                             "data_from_common_file1" => "world"
                           }),
          seed_file_double(name: "common",
                           raw_content: {
                             "data_from_common_file2" => "!!!"
                           })
        ]
      )

      expect(loader.translated_seed_files_content).to eq(
        {
          "data_from_file1" => "hello",
          "data_from_common_file1" => "world",
          "data_from_common_file2" => "!!!"
        }
      )
    end

    it "does not merge the data from seed files with a name different from the given name" do
      allow(Source::SeedFile).to receive(:all).and_return(
        [
          seed_file_double(name: seed_name,
                           raw_content: {
                             "data_from_standard_file" => "hello"
                           }),
          seed_file_double(name: "different",
                           raw_content: {
                             "data_from_different_file" => "this data will not be merged"
                           }),
          seed_file_double(name: "bim",
                           raw_content: {
                             "data_from_bim_file" => "this data will not be merged either"
                           })
        ]
      )

      expect(loader.translated_seed_files_content).to eq(
        {
          "data_from_standard_file" => "hello"
        }
      )
    end

    it "deep merges hashes with identical paths" do
      allow(Source::SeedFile).to receive(:all).and_return(
        [
          seed_file_double(name: seed_name,
                           raw_content: {
                             "welcome" => { title: "welcome title" }
                           }),
          seed_file_double(name: seed_name,
                           raw_content: {
                             "welcome" => { description: "welcome description" }
                           })
        ]
      )

      expect(loader.translated_seed_files_content).to eq(
        {
          "welcome" => {
            title: "welcome title",
            description: "welcome description"
          }
        }
      )
    end

    it "does not concat arrays with identical paths" do
      allow(Source::SeedFile).to receive(:all).and_return(
        [
          seed_file_double(name: seed_name,
                           raw_content: {
                             "project" => { "users" => ["Alice", "Bob"] }
                           }),
          seed_file_double(name: seed_name,
                           raw_content: {
                             "project" => { "users" => ["Caroline", "Devanshi"] }
                           })
        ]
      )

      expect(loader.translated_seed_files_content).to eq(
        {
          "project" => {
            "users" => ["Caroline", "Devanshi"] # last one wins...
          }
        }
      )
    end
  end
end
