#-- encoding: UTF-8
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

require 'digest/md5'

class Attachment < ActiveRecord::Base
  ALLOWED_IMAGE_TYPES = %w[ image/gif image/jpeg image/png image/tiff image/bmp ]

  belongs_to :container, polymorphic: true

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  validates_presence_of :container, :author, :content_type, :filesize
  validates_length_of :description, maximum: 255

  validate :filesize_below_allowed_maximum

  acts_as_journalized
  acts_as_event title: -> { file.name },
                url: (Proc.new do |o|
                        { controller: '/attachments', action: 'download', id: o.id, filename: o.filename }
                      end)

  mount_uploader :file, OpenProject::Configuration.file_uploader

  def filesize_below_allowed_maximum
    if filesize > Setting.attachment_max_size.to_i.kilobytes
      errors.add(:file, :file_too_large, count: Setting.attachment_max_size.to_i.kilobytes)
    end
  end

  ##
  # Returns an URL if the attachment is stored in an external (fog) attachment storage
  # or nil otherwise.
  def external_url
    url = URI.parse file.download_url # returns a path if local

    url if url.host
  rescue URI::InvalidURIError
    nil
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

  def content_disposition
    inlineable? ? 'inline' : 'attachment'
  end

  def visible?(user = User.current)
    container.attachments_visible?(user)
  end

  def deletable?(user = User.current)
    container.attachments_deletable?(user)
  end

  # images are sent inline
  def inlineable?
    is_image?
  end

  def is_image?
    ALLOWED_IMAGE_TYPES.include?(content_type)
  end

  # backwards compatibility for plugins
  alias :image? :is_image?

  def is_pdf?
    content_type == 'application/pdf'
  end

  def is_text?
    content_type =~ /\Atext\/.+/
  end

  def is_diff?
    is_text? && filename =~ /\.(patch|diff)\z/i
  end

  # Returns true if the file is readable
  def readable?
    file.readable?
  end

  # Bulk attaches a set of files to an object
  #
  # Returns a Hash of the results:
  # files: array of the attached files
  # unsaved: array of the files that could not be attached
  def self.attach_files(obj, attachments)
    attached = []
    if attachments
      attachments.each_value do |attachment|
        file = attachment['file']
        next unless file && file.size > 0
        a = Attachment.create(container: obj,
                              file: file,
                              description: attachment['description'].to_s.strip,
                              author: User.current)

        if a.new_record?
          obj.unsaved_attachments ||= []
          obj.unsaved_attachments << a
        else
          attached << a
        end
      end
    end
    { files: attached, unsaved: obj.unsaved_attachments }
  end

  def diskfile
    file.local_file
  end

  def filename
    attributes['file']
  end

  def file=(file)
    super.tap do
      set_content_type file
      set_file_size file
      set_digest file
    end
  end

  def set_file_size(file)
    self.filesize = file.size
  end

  def set_content_type(file)
    self.content_type = self.class.content_type_for(file.path) if content_type.blank?
  end

  def set_digest(file)
    self.digest = Digest::MD5.file(file.path).hexdigest
  end

  def self.content_type_for(file_path, fallback = OpenProject::ContentTypeDetector::SENSIBLE_DEFAULT)
    content_type = Redmine::MimeType.narrow_type file_path, OpenProject::ContentTypeDetector.new(file_path).detect
    content_type || fallback
  end
end
