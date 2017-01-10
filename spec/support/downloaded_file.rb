#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++
#
# Kudos to https://forum.shakacode.com/t/how-to-test-file-downloads-with-capybara/347 from
# where this code was adapted

module DownloadedFile
  PATH = Rails.root.join('tmp/test/downloads')

  extend self

  def downloads
    Dir[PATH.join("*")]
  end

  def download
    downloads.first
  end

  def download_content(ensure_content = true)
    wait_for_download
    wait_for_download_content if ensure_content
    File.read(download)
  end

  def wait_for_download
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until downloaded?
    end
  end

  def wait_for_download_content
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until has_content?
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def has_content?
    !File.read(download).empty?
  end

  def downloading?
    downloads.grep(/\.part$/).any?
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end
end
