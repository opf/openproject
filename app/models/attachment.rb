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

require "digest/md5"

class Attachment < ApplicationRecord
  enum :status, {
    uploaded: 0,
    prepared: 1,
    scanned: 2,
    quarantined: 3,
    rescan: 4
  }, prefix: true

  belongs_to :container, polymorphic: true
  belongs_to :author, class_name: "User"

  validates :author, :content_type, :filesize, :status, presence: true
  validates :description, length: { maximum: 255 }

  validate :filesize_below_allowed_maximum,
           if: -> { !internal_container? }
  validate :container_changed_more_than_once

  has_paper_trail

  # Those columns are currently not displayed in the application and are rarely used
  # at all.
  # Their purpose currently is limited to full text search where the results are not highlighted.
  # As the columns can contain a lot of text (with the exception of file_tsv) and having them included
  # leads to them being loaded when attachments are fetched, including the columns leads to a heavily
  # increased loading time
  # From a production database:
  # SELECT "attachments"."id", "attachments"."fulltext" ...
  # => 2650 ms
  # SELECT "attachments"."id" ...
  # => 1 ms
  self.ignored_columns = %w(fulltext fulltext_tsv file_tsv)

  acts_as_journalized
  acts_as_event title: -> { file.name },
                url: (Proc.new do |o|
                  { controller: "/attachments", action: "download", id: o.id, filename: o.filename }
                end)

  mount_uploader :file, OpenProject::Configuration.file_uploader

  after_commit :enqueue_jobs, on: :create, if: -> { !internal_container? }

  scope :pending_direct_upload, -> { status_prepared }
  scope :not_pending_direct_upload, -> { not_status_prepared }

  ##
  # Returns an URL if the attachment is stored in an external (fog) attachment storage
  # or nil otherwise.
  def external_url(expires_in: nil)
    url = URI.parse file.download_url(external_url_options(expires_in:)) # returns a path if local

    url if url.host
  rescue URI::InvalidURIError
    nil
  end

  ##
  # Do not include the filename in the content disposition as this may break for Unicode file names
  # specifically when using S3 for attachments. In the case of S3 the file name for the downloaded
  # file will still be correct as it's part of the URL before the query.
  def external_url_options(expires_in: nil)
    { content_disposition: content_disposition(include_filename: false),
      content_type: served_content_type,
      expires_in: }
  end

  def external_storage?
    !external_url.nil?
  end

  def increment_download
    increment!(:downloads)
  end

  def project
    # not every container has a project (example: LandingPage)
    container.respond_to?(:project) ? container.project : nil
  end

  def content_disposition(include_filename: true)
    disposition = inlineable? ? "inline" : "attachment"

    if include_filename
      "#{disposition}; filename=#{filename}"
    else
      disposition
    end
  end

  # Returns the Content-Type to use when serving this file inline in a browser.
  # Text files are normalised to text/plain (prevents script execution) with an
  # explicit charset. Non-inlineable files get application/octet-stream so the
  # browser is forced to download them.
  def served_content_type
    if is_text?
      "text/plain; charset=#{charset.presence || Setting.attachment_default_charset}"
    elsif inlineable?
      content_type
    else
      "application/octet-stream"
    end
  end

  # Returns the content type to use when serving the file to a browser.
  # For text files, ensures a charset is always present so browsers don't
  # fall back to ISO-8859-1. Preserves the real MIME subtype (e.g. text/x-ruby)
  # unlike served_content_type which normalises to text/plain for security.
  def serving_content_type
    return content_type unless is_text?

    "#{content_type}; charset=#{charset.presence || Setting.attachment_default_charset}"
  end

  def visible?(user = User.current)
    allowed_or_author?(user) do
      container.attachments_visible?(user)
    end
  end

  def deletable?(user = User.current)
    allowed_or_author?(user) do
      container.attachments_deletable?(user)
    end
  end

  def prepared?
    status_prepared?
  end

  def pending_virus_scan?
    status_uploaded? && Setting::VirusScanning.enabled?
  end

  # Determine mime types that we deem safe for inline content disposition
  # e.g., which will be loaded by the browser without forcing to download them
  def inlineable?
    is_text? || is_image? || is_movie? || is_pdf?
  end

  # rubocop:disable Naming/PredicateName
  def is_plain_text?
    OpenProject::MimeType.plain_text?(content_type)
  end

  def is_image?
    OpenProject::MimeType.image?(content_type)
  end

  def is_movie?
    OpenProject::MimeType.movie?(content_type)
  end

  # backwards compatibility for plugins
  alias :image? :is_image?

  def is_pdf?
    content_type == "application/pdf"
  end

  def is_html?
    content_type == "text/html"
  end

  def is_text?
    content_type.match?(/\Atext\/.+/) && !is_html?
  end

  def is_diff?
    is_text? && filename =~ /\.(patch|diff)\z/i
  end
  # rubocop:enable Naming/PredicateName

  # Returns true if the file is readable
  delegate :readable?, to: :file

  def containered?
    container.present?
  end

  ##
  # Retrieve a local file,
  # this may result in downloading the file first
  def diskfile
    file.local_file
  end

  ##
  # Retrieve the local file path,
  # this may result in downloading the file first to a tmpdir
  def local_path
    diskfile.path
  end

  def filename
    attributes["file"] || super
  end

  ##
  # Returns the file extension name,
  # if any (with leading dot)
  def extension
    File.extname filename
  end

  def file=(file)
    super.tap do
      set_file_size file

      set_content_type file

      if File.readable? file.path
        set_digest file
      end
    end
  end

  def set_file_size(file)
    self.filesize = file.size
  end

  def set_content_type(file)
    self.content_type, self.charset = OpenProject::ContentTypeDetector.new(file.path).detect_with_charset
  end

  def set_digest(file)
    self.digest = Digest::MD5.file(file.path).hexdigest
  end

  ##
  # Detects the content type of a file based on its actual content.
  # This method always relies on file content detection (via the `file` command)
  # and never uses filename-based narrowing (MimeType.narrow_type) to ensure
  # security-sensitive types like SVG are correctly identified even when the
  # filename extension doesn't match the actual content.
  #
  # @param file_path [String] Path to the file to analyze
  # @param fallback [String] Default content type if detection fails
  # @return [String] The detected content type
  def self.content_type_for(file_path, fallback = OpenProject::ContentTypeDetector::SENSIBLE_DEFAULT)
    # Always use ContentTypeDetector which analyzes file content, not filename
    # Do NOT use MimeType.narrow_type here as it could incorrectly narrow
    # security-sensitive types (e.g., SVG with .png extension -> image/png)
    content_type = OpenProject::ContentTypeDetector.new(file_path).detect
    content_type || fallback
  end

  def copy
    attachment = dup
    attachment.file = diskfile

    yield attachment if block_given?

    attachment
  end

  def copy!(&)
    attachment = copy(&)

    attachment.save!
  end

  def enqueue_jobs
    extract_fulltext

    if pending_virus_scan?
      Attachments::VirusScanJob.perform_later(self)
    end
  end

  def extract_fulltext
    if OpenProject::Database.allows_tsv? && (!container || container.class.attachment_tsv_extracted?)
      Attachments::ExtractFulltextJob.perform_later(id)
    end
  end

  # Extract the fulltext of any attachments where fulltext is still nil.
  # This runs inline and not in an asynchronous worker.
  def self.extract_fulltext_where_missing(run_now: true)
    return unless OpenProject::Database.allows_tsv?

    Attachment
      .where(fulltext: nil)
      .where(container_type: tsv_extracted_containers)
      .pluck(:id)
      .each do |id|
      if run_now
        Attachments::ExtractFulltextJob.perform_now(id)
      else
        Attachments::ExtractFulltextJob.perform_later(id)
      end
    end
  end

  def self.force_extract_fulltext
    return unless OpenProject::Database.allows_tsv?

    Attachment.pluck(:id).each do |id|
      Attachments::ExtractFulltextJob.perform_now(id)
    end
  end

  def self.tsv_extracted_containers
    Attachment
      .select(:container_type)
      .distinct
      .pluck(:container_type)
      .compact
      .select do |container_class|
      klass = container_class.constantize

      klass.respond_to?(:attachment_tsv_extracted?) && klass.attachment_tsv_extracted?
    rescue NameError
      false
    end
  end

  ##
  # Deletes locally cached files. This is mostly relevant for remote attachments
  # but would also apply for local attachments if things such as carrierwave
  # filters were used.
  #
  # @param age_in_seconds [Integer] Delete all cached files older than this many seconds.
  def self.clean_cached_files!(age_in_seconds: 60 * 60 * 24)
    uploader = OpenProject::Configuration.file_uploader
    cache_storage = uploader.cache_storage

    cache_storage.new(uploader.new).clean_cache! age_in_seconds
  end

  def pending_direct_upload?
    digest == "" && downloads == -1
  end

  def internal_container?
    container&.is_a?(Export)
  end

  private

  def filesize_below_allowed_maximum
    if filesize.to_i > Setting.attachment_max_size.to_i.kilobytes
      errors.add(:file, :file_too_large, count: Setting.attachment_max_size.to_i.kilobytes)
    end
  end

  def container_changed_more_than_once
    if container_id_changed_more_than_once? || container_type_changed_more_than_once?
      errors.add(:container, :unchangeable)
    end
  end

  def container_id_changed_more_than_once?
    container_id_changed? && container_id_was.present? && container_id_was != container_id
  end

  def container_type_changed_more_than_once?
    container_type_changed? && container_type_was.present? && container_type_was != container_type
  end

  def allowed_or_author?(user)
    (containered? && !(container.class.attachable_options[:only_user_allowed] && author_id != user.id) && yield) ||
      (!containered? && author_id == user.id)
  end
end
