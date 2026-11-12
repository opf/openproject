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

class DownloadList
  SETTLE_TIME = 0.25

  SHARED_PATH = Pathname.new(
    ENV.fetch("CAPYBARA_DOWNLOADED_FILE_DIR", Rails.root.join("tmp/test/downloads"))
  ).join(
    ENV.fetch("TEST_ENV_NUMBER", "1")
  ).tap(&:mkpath)

  def initialize(pattern: "*")
    @pattern = pattern
    @history = download_paths
    @latest = nil
    @observed_sizes = {}
  end

  def refresh_from(_page)
    Retryable.repeat_until_success(max_seconds: Capybara.default_max_wait_time) do
      path = next_download_path
      break if path.nil? && @latest && File.exist?(@latest)

      raise Capybara::ElementNotFound, "No completed download found" unless path

      unless download_size_stable?(path)
        raise Capybara::ElementNotFound, "Download has not finished writing"
      end

      @latest = path
    end

    @history << @latest unless @history.include?(@latest)
    self
  end

  def latest_download
    return nil if @latest.nil?

    Pathname.new(@latest)
  end

  def latest_downloaded_content
    return nil if @latest.nil?

    Pathname.new(@latest).read
  end

  def self.clear
    Dir[SHARED_PATH.join("*")].each do |file|
      FileUtils.rm_f(file)
    end
  end

  private

  def download_paths
    Dir.glob(SHARED_PATH.join(@pattern).to_s)
  end

  def next_download_path
    (download_paths - @history)
      .reject { |path| path.end_with?(".crdownload") }
      .max_by { |path| File.mtime(path) }
  end

  def download_size_stable?(path)
    size = File.size(path)
    previous_size, unchanged_since = @observed_sizes[path]
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    if size == previous_size
      size.positive? && now - unchanged_since >= SETTLE_TIME
    else
      @observed_sizes[path] = [size, now]
      false
    end
  end
end
