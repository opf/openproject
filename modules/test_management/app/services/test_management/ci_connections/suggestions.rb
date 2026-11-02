# frozen_string_literal: true

module TestManagement
  module CiConnections
    # Hints for the "New CI connection" form, taken from what OpenProject already knows about the
    # project's repositories (0015). Read only; nothing in core is changed.
    #
    # * GitLab integration (modules/gitlab_integration, webhook based, also for self-managed GitLab):
    #     gitlab_branches        project_html_url (web_url) + namespace (path_with_namespace without
    #                            the last segment) -> exact base URL and project path, sub-path
    #                            installations included. (repository holds the display name.)
    #     gitlab_merge_requests  gitlab_html_url ".../<path>/-/merge_requests/<n>" -> project URL only
    #                            (base URL and path cannot be told apart on a sub-path installation)
    #   Only rows linked to work packages of this project are used.
    # * Repositories module (core SCM): the project's repository (Git / Subversion). OpenProject
    #   cannot trigger CI for it; it is shown as a hint towards "Inbound only".
    class Suggestions
      Suggestion = Struct.new(:provider, :base_url, :repository, :url, keyword_init: true)
      LIMIT = 20

      def initialize(project)
        @project = project
      end

      def gitlab
        @gitlab ||= (from_branches + from_merge_requests).uniq { |s| s.url.downcase }.first(LIMIT)
      rescue StandardError => e
        Rails.logger.warn("test_management: GitLab suggestions unavailable (#{e.class})")
        []
      end

      # { id: 7, scm: "Git", url: "/srv/repositories/git/shop.git" } or nil
      def scm_repository
        return @scm_repository if defined?(@scm_repository)

        @scm_repository = begin
          repository = project.respond_to?(:repository) ? project.repository : nil
          repository && { id: repository.id, scm: repository.class.name.to_s.demodulize, url: repository.url.to_s }
        rescue StandardError
          nil
        end
      end

      # Connections the Repositories-module repository is attached to (0016).
      def scm_attached_to
        scm = scm_repository
        scm ? TestManagement::CiConnection.where(project_id: project.id, scm_repository_id: scm[:id]).order(:id).to_a : []
      end

      # Quick action "Set up a connection for this repository" (0016): attributes of the new-connection
      # form. Nothing is saved; the user picks the provider, checks the repository path and saves.
      # Inbound only: OpenProject does not trigger CI for a repository it only browses.
      def scm_connection_attributes
        scm = scm_repository
        return nil unless scm

        path = scm[:url].to_s.sub(%r{\A[a-z+]+://[^/]+}i, "").delete_suffix("/").delete_suffix(".git")
        { scm_repository_id: scm[:id], name: "#{scm[:scm]} repository".first(255),
          repository: path.split("/").compact_blank.last(2).join("/").first(255), inbound_only: true }
      end

      # Known server URLs (for the base URL datalist), connections of the project included.
      def base_urls
        (gitlab.filter_map(&:base_url) +
          CiConnection.where(project_id: project.id).filter_map(&:base_url)).uniq.first(LIMIT)
      end

      private

      attr_reader :project

      def from_branches
        return [] unless model?("GitlabBranch") && column?(GitlabBranch, :project_html_url)

        GitlabBranch.joins(:work_package).where(work_packages: { project_id: project.id })
                    .distinct.limit(100)
                    .pluck(:project_html_url, :namespace)
                    .filter_map { |url, namespace| branch_suggestion(url, namespace) }
      end

      def from_merge_requests
        return [] unless model?("GitlabMergeRequest")

        GitlabMergeRequest.joins(:work_packages).where(work_packages: { project_id: project.id })
                          .distinct.limit(200).pluck(:gitlab_html_url)
                          .filter_map { |url| merge_request_suggestion(url) }
      end

      def branch_suggestion(url, namespace)
        url = url.to_s.chomp("/")
        path = [namespace, url.split("/").last].compact_blank.join("/")
        return nil unless https?(url) && namespace.present? && url.downcase.end_with?("/#{path.downcase}")

        Suggestion.new(provider: "gitlab", base_url: url[0...-(path.length + 1)], repository: path, url:)
      end

      def merge_request_suggestion(url)
        project_url = url.to_s[%r{\A(https://[^?#]+?)/-/merge_requests/\d+}, 1]
        return nil unless project_url && https?(project_url)

        Suggestion.new(provider: "gitlab", url: project_url)
      end

      def https?(url)
        URI.parse(url).is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        false
      end

      def model?(name)
        Object.const_defined?(name) && name.constantize.table_exists?
      rescue StandardError
        false
      end

      def column?(model, column)
        model.column_names.include?(column.to_s)
      end
    end
  end
end
