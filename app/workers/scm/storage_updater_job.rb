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

class Scm::StorageUpdaterJob < ApplicationJob
  def initialize(repository)
    @id = repository.id

    unless repository.scm.storage_available?
      raise OpenProject::Scm::Exceptions::ScmError.new(
        I18n.t('repositories.storage.not_available')
      )
    end
  end

  def perform
    repository = Repository.find @id
    bytes = repository.scm.count_repository!

    repository.update_attributes!(
      required_storage_bytes: bytes,
      storage_updated_at: Time.now,
    )
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("StorageUpdater requested for Repository ##{@id}, which could not be found.")
  end

  ##
  # We don't want to repeat failing jobs here,
  # as they might have failed due to I/O problems and thus,
  # we rather keep the old outdated value until an event
  # triggers the update again.
  def max_attempts
    1
  end
end
