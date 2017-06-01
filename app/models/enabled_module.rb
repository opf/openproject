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

class EnabledModule < ActiveRecord::Base
  belongs_to :project

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :project_id

  after_create :module_enabled

  private

  # after_create callback used to do things when a module is enabled
  def module_enabled
    case name
    when 'wiki'
      # Create a wiki with a default start page
      if project && project.wiki.nil?
        Wiki.create(project: project, start_page: 'Wiki')
      end
    when 'repository'
      if project &&
         project.repository.nil? &&
         Setting.repositories_automatic_managed_vendor.present?
        create_managed_repository
      end
    end
  end

  def create_managed_repository
    params = {
      scm_vendor: Setting.repositories_automatic_managed_vendor,
      scm_type: Repository.managed_type
    }

    service = Scm::RepositoryFactoryService.new(project,
                                                ActionController::Parameters.new(params))
    service.build_and_save
  end
end
