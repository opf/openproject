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

require 'pathname'

def scan_repositories(path)
  repositories = Pathname.new(path).children.select(&:directory?)
  missing = []

  repositories.each do |repo|
    # Repository may be suffixed by '.git' and the like
    identifier = repo.basename.to_s.split('.')[0]
    missing << identifier if Project.find_by(identifier: identifier).nil?
  end

  missing
end

namespace :scm do
  desc 'List repositories in the current managed path that do not have an associated project'
  task find_unassociated: :environment do
    scm = OpenProject::Configuration['scm']
    if scm.nil?
      abort "No repository configuration is set.\n" \
            "(Configuration resides under key 'scm' in `config/configuration.yaml`)"
    end

    scm.each_pair do |vendor, config|
      vendor = vendor.to_s.classify
      managed = config['manages']
      repo_class = Repository.const_get(vendor)

      if managed.nil?
        puts "SCM vendor #{vendor} does not use managed repositories. Skipping."
        next
      end

      if repo_class.manages_remote?
        puts "SCM vendor #{vendor} uses remote managed repositories. Skipping."
        next
      end

      unless Dir.exists?(managed)
        $stderr.puts "WARNING: Managed repository path set to '#{managed}'," \
                     " but does not exist for SCM vendor #{vendor}!"
        next
      end

      missing = scan_repositories(managed)

      unless missing.empty?
        puts <<-WARNING

-- SCM vendor #{vendor} --

Found #{missing.length} repositories in #{managed}
without an associated project.

#{missing.map { |identifier| "> #{identifier}" }.join("\n")}

When using managed repositories of the vendor #{vendor}, OpenProject will not create
repositories whose associated project identifier is contained in the list above.

To resolve these cases, you can either:

1. Remove the affected repositories if they are only remnants of earlier projects

2. Move them out of the OpenProject managed directory '#{managed}'

3. Create an associated project and linking that repository
   as existing through the Frontend.

        WARNING
      end
    end
  end

  desc 'Setup a repository checkout base URL for the given vendor: rake scm:set_checkout_url[git=<url>, subversion=<url>]'
  task set_checkout_url: :environment do |_t, args|

    checkout_data = Setting.repository_checkout_data
    args.extras.each do |tuple|
      vendor, base_url = tuple.split('=')

      unless OpenProject::SCM::Manager.enabled?(vendor.to_sym)
        puts "Vendor #{vendor} is not enabled, skipping."
        next
      end

      checkout_data[vendor] = { 'enabled' => 1, 'base_url' => base_url }
    end
    Setting.repository_checkout_data = checkout_data
  end

  namespace :migrate do
    desc 'Migrate existing repositories to managed for a given URL prefix'
    task managed: :environment do |task, args|

      urls = args.extras
      abort "Requires at least one URL prefix to identify existing repositories" if urls.length < 1

      urls.each do |url|
        Repository.where('url LIKE ?', "#{url}%").update_all(scm_type: :managed)
      end
    end
  end
end
