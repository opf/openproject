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

require 'open3'
namespace :packager do

  def shell_setup(cmd, raise_on_error: true)
    out_and_err, status = Open3.capture2e(ENV['APP_NAME'], *cmd)

    if status.exitstatus != 0 && raise_on_error
      raise "Aborting packager setup due to error in installation. Output: #{out_and_err}"
    end
  end

  ##
  # Allow scripts to run before environment is loaded
  task before_postinstall: ['setup:relative_root']

  #
  # Allow scripts to run with environment loaded once,
  # avoids to load the environment multiple times.
  # Removes older assets
  task postinstall: [:environment, 'assets:clean', 'setup:scm'] do

    # We need to precompile assets when either
    # 1. packager requested it (e.g., due to a server prefix being set)
    # 2. When a custom Gemfile is added
    if ENV['REBUILD_ASSETS'] == 'true'
      Rake::Task['assets:precompile'].invoke
      FileUtils.chmod_R 'a+rx', "#{ENV['APP_HOME']}/public/assets/"
      shell_setup(['config:set', 'REBUILD_ASSETS=""'])
    end

    # Persist configuration
    Setting.sys_api_enabled = 1
    Setting.sys_api_key = ENV['SYS_API_KEY']
    Setting.host_name = ENV.fetch('SERVER_HOSTNAME', Setting.host_name)

    # Allow overriding the protocol setting from ENV
    # to allow instances where SSL is terminated earlier to respect that setting
    Setting.protocol =
      if ENV['SERVER_PROTOCOL_FORCE_HTTPS']
        'https'
      else
        ENV.fetch('SERVER_PROTOCOL', Setting.protocol)
      end

    # Run customization step, if it is defined.
    # Use to define custom postinstall steps required after each configure,
    # or to configure products.
    if Rake::Task.task_defined?('packager:customize')
      Rake::Task['packager:customize'].invoke
    end
  end

  namespace :setup do
    task :relative_root do
      old_relative_root = ENV['RAILS_RELATIVE_URL_ROOT'] || ''
      relative_root = ENV['SERVER_PATH_PREFIX'] || '/'

      if relative_root != '/' || "#{old_relative_root}/" != relative_root
        # Rails expects relative root not to have a trailing slash,
        # but most of our packager setup scripts require it, thus remove it here.
        new_root = relative_root.chomp('/')

        shell_setup(['config:set', "RAILS_RELATIVE_URL_ROOT=#{new_root}"])
        shell_setup(['config:set', 'REBUILD_ASSETS="true"'])
      end
    end

    task :scm do
      svn_path = ENV['SVN_REPOSITORIES'] || ''
      git_path = ENV['GIT_REPOSITORIES'] || ''

      # SCM configuration may have been skipped
      if svn_path.present? || git_path.present?
        base_url = URI::Generic.build(scheme: ENV['SERVER_PROTOCOL'], host: ENV['SERVER_HOSTNAME'])
        prefix = ENV['SERVER_PATH_PREFIX']

        checkout_data = Setting.repository_checkout_data
        if svn_path.present?
          # migrate previous repositories with reposman to managed
          Rake::Task['scm:migrate:managed'].invoke("file://#{svn_path}")
          checkout_data['subversion'] = { 'enabled' => 1, 'base_url' => URI.join(base_url, prefix, 'svn') }
        end

        if git_path.present?
          checkout_data['git'] = { 'enabled' => 1, 'base_url' => URI.join(base_url, prefix, 'git') }
        end

        Setting.repository_checkout_data = checkout_data

        # Output any remnants of existing repositories in the currently
        # configured paths of Git and Subversion.
        Rake::Task['scm:find_unassociated'].invoke
      end
    end
  end
end
