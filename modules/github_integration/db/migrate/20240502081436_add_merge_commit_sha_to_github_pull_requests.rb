class AddMergeCommitShaToGithubPullRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :github_pull_requests, :merge_commit_sha, :text
  end
end
