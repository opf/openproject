#-- encoding: UTF-8

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

class WorkPackages::Exports::CreateFromStringService
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def call(title:, content:)
    schedule_cleanup

    ServiceResult.new(success: true, result: work_package_export(title, content))
  end

  private

  def work_package_export(title, content)
    export_storage = create_export

    with_tempfile(title, content) do |file|
      store_attachment(export_storage, file)
    end

    export_storage
  end

  def create_export
    WorkPackages::Export.create user: User.current
  end

  def with_tempfile(title, content)
    name_parts = [title[0..title.rindex('.') - 1], title[title.rindex('.')..-1]]

    Tempfile.create(name_parts, encoding: content.encoding) do |file|
      file.write content

      yield file
    end
  end

  def store_attachment(storage, file)
    Attachments::CreateService
      .new(storage, author: User.current)
      .call(uploaded_file: file, description: '')
  end

  def schedule_cleanup
    WorkPackages::Exports::CleanupOutdatedJob.perform_after_grace
  end
end
