#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module FileUploader
  def self.included(base)
    base.extend ClassMethods
  end

  ##
  # Returns an URL if the attachment is stored in an external (fog) attachment storage
  # or nil otherwise.
  def external_url
    url = URI.parse download_url
    url if url.host
  rescue URI::InvalidURIError
    nil
  end

  def external_storage?
    !external_url.nil?
  end

  def local_file
    file.to_file
  end

  def download_url(_options = {})
    file.is_path? ? file.path : file.url
  end

  def cache_dir
    self.class.cache_dir
  end

  def readable?
    return false unless file && local_file

    File.readable?(local_file)
  end

  # store! nil's the cache_id after it finishes so we need to remember it for deletion
  def remember_cache_id(_new_file)
    @cache_id_was = cache_id
  end

  def delete_tmp_dir(_new_file)
    # make sure we don't delete other things accidentally by checking the name pattern
    if @cache_id_was.present? && @cache_id_was =~ /\A\d{8}-\d{4}-\d+-\d{4}\z/
      FileUtils.rm_rf(File.join(cache_dir, @cache_id_was))
    end
  rescue StandardError => e
    Rails.logger.error "Failed cleanup of upload file #{@cache_id_was}: #{e}"
  end

  # remember the tmp file
  def cache!(new_file = sanitized_file)
    super
    @old_tmp_file = new_file
  rescue StandardError => e
    Rails.logger.error "Failed cache! of temporary upload file: #{e}"
  end

  def delete_old_tmp_file(_dummy)
    @old_tmp_file.try :delete
  rescue StandardError => e
    Rails.logger.error "Failed cleanup of temporary upload file: #{e}"
  end

  module ClassMethods
    def cache_dir
      @cache_dir ||= File.join(Dir.tmpdir, 'op_uploaded_files')
    end
  end
end
