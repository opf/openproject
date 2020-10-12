#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Attachments::CreateService
  attr_reader :container, :author

  def initialize(container, author:)
    @container = container
    @author = author
  end

  ##
  # Adds and saves the uploaded file as attachment of the given container.
  # In case the container supports it, a journal will be written.
  #
  # An ActiveRecord::RecordInvalid error is raised if any record can't be saved.
  def call(uploaded_file:, description:)
    if container.nil?
      create_attachment(uploaded_file, description)
    elsif container.class.journaled?
      create_journalized(uploaded_file, description)
    else
      create_unjournalized(uploaded_file, description)
    end
  end

  private

  def create_journalized(uploaded_file, description)
    OpenProject::Mutex.with_advisory_lock_transaction(container) do
      attachment = create_attachment(uploaded_file, description)
      # Get the latest attachments to ensure having them all for journalization.
      # We just created an attachment and a different worker might have added attachments
      # in the meantime, e.g when bulk uploading.
      container.attachments.reload

      add_journal
      save_container

      attachment
    end
  end

  def create_unjournalized(uploaded_file, description)
    create_attachment(uploaded_file, description).tap do
      save_container
    end
  end

  def add_journal
    container.add_journal author
  end

  def create_attachment(uploaded_file, description)
    attachment = Attachment.new(file: uploaded_file,
                                container: container,
                                description: description,
                                author: author)

    attachment.save!
    attachment
  end

  def build_attachment(uploaded_file, description)
    container.attachments.build(file: uploaded_file, description: description, author: author)
  end

  def save_container
    # We allow invalid containers to be saved as
    # adding the attachments does not change the validity of the container
    # but without that leeway, the user needs to fix the container before
    # the attachment can be added.
    container.save!(validate: false)
  end
end
