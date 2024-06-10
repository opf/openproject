#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Cron
  class CheckDeployStatusJob < ApplicationJob
    include OpenProject::GithubIntegration::NotificationHandler::Helper

    priority_number :low

    def perform
      deploy_targets.find_each do |deploy_target|
        sha = openproject_core_sha deploy_target.host, deploy_target.api_key

        if sha.present?
          pull_requests.find_each do |pull_request|
            check_deploy_status deploy_target, pull_request, sha
          end
        else
          OpenProject.logger.error "Failed to retrieve core SHA for deploy target #{deploy_target.host}"
        end
      end
    end

    def deploy_targets
      DeployTarget.all
    end

    def pull_requests
      GithubPullRequest
        .closed
        .where.not(merge_commit_sha: nil)
    end

    def check_deploy_status(deploy_target, pull_request, core_sha)
      status_check = deploy_status_check deploy_target, pull_request

      # we already checked this PR against the given core SHA, so no need to check again
      return if status_check.core_sha == core_sha

      # if the commit is contained, it has been deployed
      if commit_contains? core_sha, pull_request.merge_commit_sha
        update_deploy_status pull_request, deploy_target
      else
        status_check.update core_sha: # remember last checked SHA to not check twice
      end
    end

    ##
    # Marks the given PR as deployed and removes the last status check
    # as it won't be needed anymore. This is because only closed (not yet deployed)
    # PRs are ever checked for their deployment status.
    def update_deploy_status(pull_request, deploy_target)
      host = deploy_target.host

      ActiveRecord::Base.transaction do
        delete_status_check pull_request, deploy_target
        pull_request.update! state: "deployed"

        comment_on_referenced_work_packages(
          pull_request.work_packages,
          comment_user,
          "[#{pull_request.repository}##{pull_request.number}](#{pull_request.github_html_url}) deployed to [#{host}](https://#{host})"
        )
      end
    end

    def delete_status_check(pull_request, deploy_target)
      # we use `select` and delete it this way to also cover
      # not-yet-persisted records
      checks = pull_request
        .deploy_status_checks
        .select { |c| c.deploy_target == deploy_target }

      pull_request.deploy_status_checks.delete(checks)
    end

    ##
    # Ideally this would be the github user, but we don't really have a way
    # to identify it outside of the webhook request cycle.
    def comment_user
      User.system
    end

    def deploy_status_check(deploy_target, pull_request)
      pull_request
        .deploy_status_checks
        .find_or_initialize_by(
          deploy_target:,
          github_pull_request: pull_request
        )
    end

    def openproject_core_sha(host, api_token)
      res = introspection_request(host, api_token)

      return nil if handle_request_error res, "Could not get OpenProject core SHA"

      info = JSON.parse res.body.to_s

      info["coreSha"].presence
    end

    def introspection_request(host, api_token)
      OpenProject.httpx.basic_auth("apikey", api_token).get("https://#{host}/api/v3")
    end

    ##
    # Uses the GitHub APIs compare endpoint to compare the currently deployed base commit
    # and a merge commit from a PR.
    #
    # If the latter is included in the former, there will be 'ahead_by' and 'behind_by'
    # in the response. 'aheady_by' will be 0, 'behind_by' greater than 0.
    #
    # If the commits are not included in the same branch, these fields
    # will not be present at all.
    def commit_contains?(base_commit_sha, merge_commit_sha)
      data = compare_commits base_commit_sha, merge_commit_sha

      return false if data.nil?

      status_identical?(data) || status_behind?(data)
    end

    def status_identical?(data)
      status = data["status"].presence

      status == "identical"
    end

    def status_behind?(data)
      status = data["status"].presence
      ahead_by = data["ahead_by"].presence
      behind_by = data["behind_by"].presence

      status == "behind" && ahead_by == 0 && (behind_by.present? && behind_by > 0)
    end

    def compare_commits(sha_a, sha_b)
      res = compare_commits_request sha_a, sha_b

      return nil if handle_request_error res, "Failed to compare commits"

      JSON.parse res.body.read
    end

    def handle_request_error(res, error_prefix)
      if res.is_a? HTTPX::ErrorResponse
        OpenProject.logger.error "#{error_prefix}: #{res.error}"
      elsif res.status == 404
        OpenProject.logger.error "#{error_prefix}: not found"
      elsif res.status != 200
        OpenProject.logger.error "#{error_prefix}: #{res.body}"
      else
        return false
      end

      true
    end

    def compare_commits_request(sha_a, sha_b)
      OpenProject.httpx.get(compare_commits_url(sha_a, sha_b))
    end

    def compare_commits_url(sha_a, sha_b)
      "https://api.github.com/repos/opf/openproject/compare/#{sha_a}...#{sha_b}"
    end
  end
end
