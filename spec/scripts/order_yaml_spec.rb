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
require "open3"
require "tempfile"

RSpec.describe "script/order_yaml", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  let(:script) { File.expand_path("../../script/order_yaml", __dir__) }

  let(:unordered) { <<~YAML }
    # header comment

    ---
    en:
      no_results: >
        nothing to display


      let_this_be_here: 1

      # before aaa
      activities:  # aaa
        xindex:
          no_results: no activity in this time frame



        # before bbb
        work_packages:  # bbb
          label_sort_desc: "Newest on top"
          # before folded
          folded: >
            first


            second
          label_who: Who?
          # before changed
          changed: "changed"
          literal: |
            first


            second
          created: "created"
          label_sort_asc: "Newest at the bottom"
  YAML

  let(:ordered) { <<~YAML }
    # header comment

    ---
    en:
      # before aaa
      activities:  # aaa
        # before bbb
        work_packages:  # bbb
          # before changed
          changed: "changed"
          created: "created"
          # before folded
          folded: >
            first


            second
          label_sort_asc: "Newest at the bottom"
          label_sort_desc: "Newest on top"
          label_who: Who?
          literal: |
            first


            second



        xindex:
          no_results: no activity in this time frame

      let_this_be_here: 1
      no_results: >
        nothing to display


  YAML

  let(:unexpected) { <<~YAML }
    - b
    - a
  YAML

  def with_yaml_file(content)
    Tempfile.create(["order_yaml", ".yml"]) do |file|
      file.write(content)
      file.flush
      yield file.path
    end
  end

  def run_script(content)
    with_yaml_file(content) do |path|
      Open3.capture3(script, path)
    end
  end

  it "orders keys alphabetically, keeping comments and blank lines in place" do
    stdout, stderr, status = run_script(unordered)

    expect(status).to be_success
    expect(stdout).to eq(ordered)
    expect(stderr).to be_empty
  end

  it "leaves an already ordered file unchanged" do
    stdout, stderr, status = run_script(ordered)

    expect(status).to be_success
    expect(stdout).to eq(ordered)
    expect(stderr).to be_empty
  end

  it "fails when the document root is not a hash" do
    stdout, stderr, status = run_script(unexpected)

    expect(status).not_to be_success
    expect(stdout).to be_empty
    expect(stderr).to include("document root is not a hash or not in block style")
  end

  it "rewrites multiple files in place with -i" do
    other_unordered = <<~YAML
      b: 2
      a: 1
    YAML
    other_ordered = <<~YAML
      a: 1
      b: 2
    YAML

    with_yaml_file(unordered) do |path_a|
      with_yaml_file(other_unordered) do |path_b|
        stdout, stderr, status = Open3.capture3(script, "-i", path_a, path_b)

        expect(status).to be_success
        expect(stdout).to be_empty
        expect(stderr).to be_empty
        expect(File.read(path_a)).to eq(ordered)
        expect(File.read(path_b)).to eq(other_ordered)
      end
    end
  end

  it "stops processing remaining files when one fails" do
    unchanged = <<~YAML
      b: 2
      a: 1
    YAML

    with_yaml_file(unexpected) do |bad_path|
      with_yaml_file(unchanged) do |good_path|
        stdout, stderr, status = Open3.capture3(script, "-i", bad_path, good_path)

        expect(status).not_to be_success
        expect(stdout).to be_empty
        expect(stderr).to include("document root is not a hash or not in block style")
        expect(File.read(good_path)).to eq(unchanged)
      end
    end
  end

  it "aborts when the parsed result is not the same" do
    stdout, stderr, status = run_script(<<~YAML)
      b: 1

      a: |+ # blank line above moves below this block and changes its value
        text
    YAML

    expect(status).not_to be_success
    expect(stdout).to be_empty
    expect(stderr).to include("ordering changed content of ")
  end
end
