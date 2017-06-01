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

require 'open_project/scm/adapters/subversion'

class Repository::Subversion < Repository
  validates_presence_of :url
  validates_format_of :url, with: /\A(http|https|svn(\+[^\s:\/\\]+)?|file):\/\/.+\z/i

  def self.scm_adapter_class
    OpenProject::Scm::Adapters::Subversion
  end

  def configure(scm_type, _args)
    if scm_type == self.class.managed_type
      unless manageable?
        raise OpenProject::Scm::Exceptions::RepositoryBuildError.new(
          I18n.t('repositories.managed.error_not_manageable')
        )
      end

      self.root_url = managed_repository_path
      self.url = managed_repository_url
    end
  end

  def self.authorization_policy
    ::Scm::SubversionAuthorizationPolicy
  end

  def self.permitted_params(params)
    super(params).merge(params.permit(:login, :password))
  end

  def self.supported_types
    types = [:existing]
    types << managed_type if manageable?

    types
  end

  def managed_repo_created
    scm.create_empty_svn
  end

  def repository_type
    'Subversion'
  end

  def supports_directory_revisions?
    true
  end

  def repo_log_encoding
    'UTF-8'
  end

  def latest_changesets(path, rev, limit = 10)
    revisions = scm.revisions(path, rev, nil, limit: limit)
    revisions ? changesets.where(revision: revisions.map(&:identifier)).order('committed_on DESC').includes(:user) : []
  end

  # Returns a path relative to the url of the repository
  def relative_path(path)
    path.gsub(Regexp.new("^\/?#{Regexp.escape(relative_url)}\/"), '')
  end

  def fetch_changesets
    scm_info = scm.info
    if scm_info
      # latest revision found in database
      db_revision = latest_changeset ? latest_changeset.revision.to_i : 0
      # latest revision in the repository
      scm_revision = scm_info.lastrev.identifier.to_i
      if db_revision < scm_revision
        logger.debug "Fetching changesets for repository #{url}" if logger && logger.debug?
        identifier_from = db_revision + 1
        while (identifier_from <= scm_revision)
          # loads changesets by batches of 200
          identifier_to = [identifier_from + 199, scm_revision].min
          revisions = scm.revisions('', identifier_to, identifier_from, with_paths: true)
          revisions.reverse_each do |revision|
            transaction do
              changeset = Changeset.create(repository: self,
                                           revision: revision.identifier,
                                           committer: revision.author,
                                           committed_on: revision.time,
                                           comments: revision.message)

              revision.paths.each do |change|
                changeset.create_change(change)
              end unless changeset.new_record?
            end
          end unless revisions.nil?
          identifier_from = identifier_to + 1
        end
      end
    end
  rescue => e
    Rails.logger.error("Failed to fetch changesets from repository: #{e.message}")
  end

  private

  # Returns the relative url of the repository
  # Eg: root_url = file:///var/svn/foo
  #     url      = file:///var/svn/foo/bar
  #     => returns /bar
  def relative_url
    @relative_url ||= url.gsub(Regexp.new("^#{Regexp.escape(root_url || scm.root_url)}", Regexp::IGNORECASE), '')
  end
end
