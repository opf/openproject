#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class AddAttachmentService
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
  def add_attachment(uploaded_file:, description:)
    attachment = Attachment.new(file: uploaded_file,
                                container: container,
                                description: description,
                                author: author)
    save attachment

    attachment
  end

  private

  def save(attachment)
    ActiveRecord::Base.transaction do
      attachment.save!

      if container.respond_to? :add_journal
        # reload to get the newly added attachment
        container.attachments.reload
        container.add_journal author
        # We allow invalid containers to be saved as
        # adding the attachments does not change the validity of the container
        # but without that leeway, the user needs to fix the container before
        # the attachment can be added.
        container.save!(validate: false)
      end
    end
  end
end
