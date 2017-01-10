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

##
# Implements a repository factory for building temporary and permanent repositories.
class Scm::RepositoryFactoryService
  attr_reader :project, :params, :repository

  def initialize(project, params)
    @project = project
    @params = params
  end

  ##
  # Build a full repository from a given scm_type
  # and persists it.
  #
  # @return [Boolean] true iff the repository was built
  def build_and_save
    build_guarded do
      repository = build_with_type(params.fetch(:scm_type).to_sym)
      if repository.save
        repository
      else
        raise OpenProject::Scm::Exceptions::RepositoryBuildError.new(
          repository.errors.full_messages.join("\n")
        )
      end
    end
  end

  ##
  # Build a temporary repository used only for determining availabe settings and types
  # of that particular vendor.
  #
  # @return [Boolean] true iff the repository was built
  def build_temporary
    build_guarded do
      build_with_type(nil)
    end
  end

  def build_error
    I18n.t('repositories.errors.build_failed', reason: @build_failed_msg)
  end

  private

  ##
  # Helper to actually build the repository and return it.
  # May raise +OpenProject::Scm::Exceptions::RepositoryBuildError+ internally.
  #
  # @param [Symbol] scm_type Type to build the repository with. May be nil
  #                          during temporary build
  def build_with_type(scm_type)
    Repository.build(
      project,
      params.fetch(:scm_vendor).to_sym,
      params.fetch(:repository, {}),
      scm_type
    )
  end

  def build_guarded
    @repository = yield
    @repository.present?
  rescue OpenProject::Scm::Exceptions::RepositoryBuildError => e
    @build_failed_msg = e.message
    nil
  end
end
