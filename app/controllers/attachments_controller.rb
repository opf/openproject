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

class AttachmentsController < ApplicationController
  before_action :find_project
  before_action :file_readable, :read_authorize, except: :destroy
  before_action :delete_authorize, only: :destroy

  def download
    url = @attachment.external_url

    if url
      redirect_to url.to_s
    else
      serve_attachment @attachment
    end
  end

  def destroy
    # Make sure association callbacks are called
    @attachment.container.attachments.delete(@attachment)

    respond_to do |format|
      format.html do redirect_to url_for(destroy_response_url(@attachment.container)) end
      format.js
    end
  end

  private

  def find_project
    @attachment = Attachment.find(params[:id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
    @project = @attachment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Checks that the file exists and is readable
  def file_readable
    @attachment.readable? ? true : render_404
  end

  def read_authorize
    @attachment.visible? ? true : deny_access
  end

  def delete_authorize
    @attachment.deletable? ? true : deny_access
  end

  def destroy_response_url(container)
    url_for(container.is_a?(WikiPage) ? [@project, container.wiki] : container)
  end

  def serve_attachment(attachment)
    if attachment.container.is_a?(Version) || attachment.container.is_a?(Project)
      attachment.increment_download
    end

    # browsers should not try to guess the content-type
    response.headers['X-Content-Type-Options'] = 'nosniff'

    send_file attachment.diskfile, filename: filename_for_content_disposition(attachment.filename),
                                   type: attachment.content_type,
                                   disposition: attachment.content_disposition
  end
end
