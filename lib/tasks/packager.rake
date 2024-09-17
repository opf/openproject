#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "open3"
namespace :packager do
  def shell_setup(cmd, raise_on_error: true)
    out_and_err, status = Open3.capture2e(ENV.fetch("APP_NAME", nil), *cmd)

    if status.exitstatus != 0 && raise_on_error
      raise "Aborting packager setup due to error in installation. Output: #{out_and_err}"
    end
  end

  ##
  # Allow scripts to run before environment is loaded
  task before_postinstall: ["setup:relative_root"]

  #
  # Allow scripts to run with environment loaded once,
  # avoids to load the environment multiple times.
  # Removes older assets
  task postinstall: [:environment, "assets:clean", "setup:scm"] do
    # We need to precompile assets when either
    # 1. packager requested it
    # 2. user requested frontend compilation with RECOMPILE_ANGULAR_ASSETS
    if ENV["RECOMPILE_RAILS_ASSETS"] == "true" || ENV["RECOMPILE_ANGULAR_ASSETS"] == "true"
      Rake::Task["assets:precompile"].invoke
      FileUtils.chmod_R "a+rx", "#{ENV.fetch('APP_HOME', nil)}/public/assets/"

      # Unset rails request to recompile
      # but keep RECOMPILE_ANGULAR_ASSETS as it's user defined
      shell_setup(["config:set", 'RECOMPILE_RAILS_ASSETS=""'])
    end

    # Clear any caches
    OpenProject::Cache.clear

    # Persist configuration
    Setting.sys_api_enabled = 1
    Setting.sys_api_key = ENV.fetch("SYS_API_KEY", nil)
    env_host_name = ENV["SERVER_HOSTNAME"]
    # Write the ENV provided host name as a setting so it is no longer writable
    if env_host_name.present?
      shell_setup(["config:set", "OPENPROJECT_HOST__NAME=#{env_host_name}"])
    end

    # SERVER_PROTOCOL is set by the packager apache2 addon
    # other SERVER_PROTOCOL_xxx variables can be manually set by user
    if ENV["SERVER_PROTOCOL_HTTPS_NO_HSTS"]
      # Allow setting only HTTPS setting without enabling FORCE__SSL
      # due to external proxy configuration. This avoids activation of HSTS headers.
      shell_setup(["config:set", "OPENPROJECT_HTTPS=true"])
      shell_setup(["config:set", "OPENPROJECT_HSTS=false"])
    elsif ENV["SERVER_PROTOCOL_FORCE_HTTPS"] || ENV.fetch("SERVER_PROTOCOL", Setting.protocol) == "https"
      # Allow overriding the protocol setting from ENV
      # to allow instances where SSL is terminated earlier to respect that setting
      shell_setup(["config:set", "OPENPROJECT_HTTPS=true"])
      shell_setup(["config:set", "OPENPROJECT_HSTS=true"])
    else
      shell_setup(["config:set", "OPENPROJECT_HTTPS=false"])
      shell_setup(["config:set", "OPENPROJECT_HSTS=false"])
    end

    # Run customization step, if it is defined.
    # Use to define custom postinstall steps required after each configure,
    # or to configure products.
    if Rake::Task.task_defined?("packager:customize")
      Rake::Task["packager:customize"].invoke
    end
  end

  namespace :setup do
    task :relative_root do
      old_relative_root = ENV.fetch("RAILS_RELATIVE_URL_ROOT", "")
      relative_root = ENV.fetch("SERVER_PATH_PREFIX", "/")

      if relative_root != "/" || "#{old_relative_root}/" != relative_root
        # Rails expects relative root not to have a trailing slash,
        # but most of our packager setup scripts require it, thus remove it here.
        new_root = relative_root.chomp("/")

        shell_setup(["config:set", "RAILS_RELATIVE_URL_ROOT=#{new_root}"])
      end
    end

    task :scm do
      svn_path = ENV.fetch("SVN_REPOSITORIES", "")
      git_path = ENV.fetch("GIT_REPOSITORIES", "")

      # SCM configuration may have been skipped
      if svn_path.present? || git_path.present?
        base_url = URI::Generic.build(scheme: ENV.fetch("SERVER_PROTOCOL", nil), host: ENV.fetch("SERVER_HOSTNAME", nil))
        prefix = ENV.fetch("SERVER_PATH_PREFIX", nil)

        checkout_data = Setting.repository_checkout_data
        if svn_path.present?
          # migrate previous repositories with reposman to managed
          Rake::Task["scm:migrate:managed"].invoke("file://#{svn_path}")
          checkout_data["subversion"] = { "enabled" => 1, "base_url" => URI.join(base_url, prefix, "svn").to_s }
        end

        if git_path.present?
          checkout_data["git"] = { "enabled" => 1, "base_url" => URI.join(base_url, prefix, "git").to_s }
        end

        Setting.repository_checkout_data = checkout_data

        # Output any remnants of existing repositories in the currently
        # configured paths of Git and Subversion.
        Rake::Task["scm:find_unassociated"].invoke
      end
    end
  end
end
