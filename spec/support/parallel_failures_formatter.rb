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
  ANNOTATION_MESSAGE_LIMIT = 300
  ANNOTATION_MESSAGE_LINES = 5

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
    @failure_notifications = notification.failure_notifications
  end

  def dump_summary(notification)
    return if notification.failed_examples.empty?

    write_locked(@report, "#{@failures}#{notification.colorized_rerun_commands}\n\n")
    write_locked(@annotations, @failure_notifications.map { github_annotation(it) }.join)
    write_locked(@summary, @failure_notifications.map { summary_section(it) }.join)
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

  def github_annotation(failure)
    example = failure.example
    file = example.metadata[:file_path].delete_prefix("./")
    title = escape_annotation_property(example.full_description)
    message = escape_annotation_data(annotation_message(failure))

    "::error file=#{escape_annotation_property(file)},line=#{failure_line(failure)},title=#{title}::#{message}\n"
  end

  def failure_line(failure)
    example = failure.example
    spec_file_prefix = "#{File.expand_path(example.metadata[:file_path])}:"
    frame = failure.exception.backtrace.to_a.find { it.start_with?(spec_file_prefix) }

    frame ? frame.delete_prefix(spec_file_prefix).to_i : example.metadata[:line_number]
  end

  def annotation_message(failure)
    exception = failure.exception
    lines = exception.message.lines.map(&:rstrip).reject(&:empty?).first(ANNOTATION_MESSAGE_LINES)
    message = "#{exception.class}:\n#{lines.join("\n")}"

    message.length > ANNOTATION_MESSAGE_LIMIT ? "#{message[0, ANNOTATION_MESSAGE_LIMIT]}…" : message
  end

  def summary_section(failure)
    <<~MARKDOWN
      ### #{failure.example.full_description}

      ```
      #{failure_message(failure)}

      #{failure.formatted_backtrace.join("\n")}
      ```

      ```
      rspec #{failure.example.location_rerun_argument}
      ```

    MARKDOWN
  end

  def failure_message(failure)
    failure.message_lines.join("\n").strip[0, MESSAGE_LIMIT]
  end

  def escape_annotation_data(text)
    text.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
  end

  def escape_annotation_property(text)
    escape_annotation_data(text).gsub(":", "%3A").gsub(",", "%2C")
  end
end
