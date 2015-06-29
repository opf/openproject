#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Implements a repository factory for building temporary and permanent repositories.
Scm::RepositoryFactoryService = Struct.new :project, :params do
  ##
  # Build a full repository from a given scm_type
  #
  # @return [Boolean] true iff the repository was built
  def build
    @repository = Repository.build(project,
                                   params[:scm_vendor],
                                   params.fetch(:repository, {}),
                                   params.fetch(:scm_type).to_sym
                                  )

    @repository
  rescue Repository::BuildFailed
    nil
  end

  ##
  # Build a temporary repository used only for determining availabe settings and types
  # of that particular vendor.
  #
  # @return [Boolean] true iff the repository was built
  def build_temporary
    @repository = Repository.build_scm_class(params[:scm_vendor]).new
    @repository.project = project
    @repository.scm_type = params[:scm_type]

    @repository
  rescue Repository::BuildFailed
    nil
  end
end
