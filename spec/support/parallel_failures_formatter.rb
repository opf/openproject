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

class ParallelFailuresFormatter
  RSpec::Core::Formatters.register self, :dump_failures, :dump_summary

  ANNOTATIONS_PATH = "tmp/parallel_failures_annotations.log"
  SUMMARY_PATH = "tmp/parallel_failures_summary.md"
  MESSAGE_LIMIT = 1000

  def initialize(output)
    # RSpec opens --out files for writing, so concurrent processes would
    # overwrite each other's reports.
    output.close
    @report = File.open(output.path, "a")
    @annotations = truncate_and_append(ANNOTATIONS_PATH)
    @summary = truncate_and_append(SUMMARY_PATH)
  end

  def dump_failures(notification)
    @failures = notification.fully_formatted_failed_examples
  end

  def dump_summary(notification)
    failed_examples = notification.failed_examples
    return if failed_examples.empty?

    write_locked(@report, "#{@failures}#{notification.colorized_rerun_commands}\n\n")
    write_locked(@annotations, failed_examples.map { github_annotation(it) }.join)
    write_locked(@summary, failed_examples.map { summary_row(it) }.join)
  end

  private

  def truncate_and_append(path)
    File.write(path, "")
    File.open(path, "a")
  end

  def write_locked(file, text)
    file.flock(File::LOCK_EX)
    begin
      file.write(text)
      file.flush
    ensure
      file.flock(File::LOCK_UN)
    end
  end

  def github_annotation(example)
    file = example.metadata[:file_path].delete_prefix("./")
    line = example.metadata[:line_number]
    title = escape_annotation_property(example.full_description)
    message = escape_annotation_data(failure_message(example))

    "::error file=#{escape_annotation_property(file)},line=#{line},title=#{title}::#{message}\n"
  end

  def summary_row(example)
    rerun = "`rspec #{example.location_rerun_argument}`"
    description = escape_markdown_cell(example.full_description)
    error = escape_markdown_cell(failure_message(example))

    "| #{rerun} | #{description} | #{error} |\n"
  end

  def failure_message(example)
    exception = example.execution_result.exception
    "#{exception.class}: #{exception.message.strip}"[0, MESSAGE_LIMIT]
  end

  def escape_annotation_data(text)
    text.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
  end

  def escape_annotation_property(text)
    escape_annotation_data(text).gsub(":", "%3A").gsub(",", "%2C")
  end

  def escape_markdown_cell(text)
    text.gsub("|", "\\|").gsub(/\s*\n\s*/, " ")
  end
end
