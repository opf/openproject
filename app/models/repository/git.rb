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

require 'open_project/scm/adapters/git'

class Repository::Git < Repository
  validates_presence_of :url

  def self.scm_adapter_class
    OpenProject::Scm::Adapters::Git
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

  def self.permitted_params(params)
    super(params).merge(params.permit(:path_encoding))
  end

  def self.supported_types
    types = [:local]
    types << managed_type if manageable?

    types
  end

  def managed_repo_created
    scm.initialize_bare_git
  end

  def repository_identifier
    "#{super}.git"
  end

  def repository_type
    'Git'
  end

  ##
  # Git doesn't like local urls when visiting
  # the repository, thus always use the path.
  def managed_repository_url
    managed_repository_path
  end

  def supports_directory_revisions?
    true
  end

  def repo_log_encoding
    'UTF-8'
  end

  def self.authorization_policy
    ::Scm::GitAuthorizationPolicy
  end

  # Returns the identifier for the given git changeset
  def self.changeset_identifier(changeset)
    changeset.scmid
  end

  # Returns the readable identifier for the given git changeset
  def self.format_changeset_identifier(changeset)
    format_revision(changeset.revision)
  end

  def self.format_revision(revision)
    revision[0, 8]
  end

  def branches
    scm.branches
  end

  def tags
    scm.tags
  end

  def find_changeset_by_name(name)
    return nil if name.nil? || name.empty?
    e = changesets.where(['revision = ?', name.to_s]).first
    return e if e
    changesets.where(['scmid LIKE ?', "#{name}%"]).first
  end

  # With SCM's that have a sequential commit numbering, redmine is able to be
  # clever and only fetch changesets going forward from the most recent one
  # it knows about.  However, with git, you never know if people have merged
  # commits into the middle of the repository history, so we should parse
  # the entire log. Since it's way too slow for large repositories, we only
  # parse 1 week before the last known commit.
  # The repository can still be fully reloaded by calling #clear_changesets
  # before fetching changesets (eg. for offline resync)
  def fetch_changesets
    c = changesets.order('committed_on DESC').first
    since = (c ? c.committed_on - 7.days : nil)

    revisions = scm.revisions('', nil, nil, all: true, since: since, reverse: true)
    return if revisions.nil? || revisions.empty?

    recent_changesets = changesets.where(['committed_on >= ?', since])

    # Clean out revisions that are no longer in git
    recent_changesets.each do |c| c.destroy unless revisions.detect { |r| r.scmid.to_s == c.scmid.to_s } end

    # Subtract revisions that redmine already knows about
    recent_revisions = recent_changesets.map(&:scmid)
    revisions.reject! do |r| recent_revisions.include?(r.scmid) end

    # Save the remaining ones to the database
    unless revisions.nil?
      revisions.each do |rev|
        transaction do
          changeset = Changeset.new(
            repository: self,
            revision:   rev.identifier,
            scmid:      rev.scmid,
            committer:  rev.author,
            committed_on: rev.time,
            comments:   rev.message)

          if changeset.save
            rev.paths.each do |file|
              Change.create(
                changeset: changeset,
                action:    file[:action],
                path:      file[:path])
            end
          end
        end
      end
    end
  end

  def latest_changesets(path, rev, limit = 10)
    revisions = scm.revisions(path, nil, rev, limit: limit, all: false)
    return [] if revisions.nil? || revisions.empty?

    changesets.where(['scmid IN (?)', revisions.map!(&:scmid)])
      .order('committed_on DESC')
  end
end
