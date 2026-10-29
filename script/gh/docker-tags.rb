#!/usr/bin/env ruby
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

require "optparse"
require "rubygems"

class Tag
  def initialize(tag)
    @tag = tag
  end

  def semver?
    @tag.match?(/^v(\d+\.\d+\.\d+.*)$/)
  end

  def rc?
    @tag.match?(/-rc$/)
  end

  def version
    if semver?
      @tag.sub(/^v/, "").sub(/-rc$/, "")
    else
      @tag.sub(/-rc$/, "")
    end
  end

  def to_semver_docker_tags
    if semver?
      tags = [
        "type=semver,pattern={{version}},value=#{version}",
        "type=semver,pattern={{major}}.{{minor}},value=#{version}"
      ]

      if latest_patch_for_major?
        tags << "type=semver,pattern={{major}},value=#{version}"
      end

      tags
    elsif rc?
      [
        "type=raw,value=#{major}.#{minor}-rc",
        "type=raw,value=#{major}-rc"
      ]
    else
      ["type=raw,value=#{version}"]
    end
  end

  def major
    return unless semver? || rc?

    version.split(".")[0]
  end

  def minor
    return unless semver? || rc?

    version.split(".")[1]
  end

  private

  def latest_patch_for_major?
    return false unless stable_semver?

    latest = git_stable_semver_tags
      .select { |tag_version| tag_version.segments[0].to_s == major }
      .max

    latest == Gem::Version.new(version)
  end

  def stable_semver?
    @tag.match?(/^v\d+\.\d+\.\d+$/)
  end

  def git_stable_semver_tags
    @git_stable_semver_tags ||= begin
      tags = `git tag --list 'v*'`.lines.map(&:strip)
      tags
        .select { |raw| raw.match?(/^v\d+\.\d+\.\d+$/) }
        .map { |raw| Gem::Version.new(raw.delete_prefix("v")) }
    end
  end
end

def write_to_github_output(key, value)
  return unless ENV["GITHUB_OUTPUT"]

  puts "Writing '#{key}' to GitHub output..."

  if value.nil? || value.strip.empty?
    puts "Error: '#{key}' output is empty"
    exit 1
  end

  File.open(ENV["GITHUB_OUTPUT"], "a") do |f|
    if value.include?("\n")
      f.puts "#{key}<<EOF"
      f.puts value
      f.puts "EOF"
    else
      f.puts "#{key}=#{value}"
    end
  end
end

def main # rubocop:disable Metrics/AbcSize
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [TAG] [options]"
    opts.on("--format-for-docker", "Output formatted tags for docker metadata") do
      options[:format_for_docker] = true
    end
    opts.on("--version", "Output first tag as version") do
      options[:version] = true
    end
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  tag = Tag.new(ARGV.first)
  if options[:version]
    output = tag.version
    puts output
    write_to_github_output("version", output)
  elsif options[:format_for_docker]
    output = tag.to_semver_docker_tags.join("\n")
    puts output
    write_to_github_output("docker_tags", output)
  else
    puts "Error: Must specify either --version or --format-for-docker"
    exit 1
  end
end

main if __FILE__ == $0
