# frozen_string_literal: true

# "Run in CI" (0011): OpenProject triggers the CI job that executes the automated cases of a
# run, a folder or a single case.
# - CI connections get what a trigger needs: the workflow file / Jenkins job (repository holds
#   the job path for Jenkins and the numeric repo id for Woodpecker), the git ref, a user name
#   (Jenkins) and a second encrypted secret: the GitLab pipeline trigger token or the Jenkins
#   "Trigger builds remotely" token. The access token column is reused for the API token.
# - runs record the last trigger: status (triggered | failed), the CI URL, the error and when.
#   The iteration created for the trigger keeps the same details in ci_metadata["trigger"].
class AddRunInCiToTestManagement < ActiveRecord::Migration[8.0]
  def change
    change_table :tm_ci_connections, bulk: true do |t|
      t.string :workflow, limit: 255
      t.string :trigger_ref, limit: 255
      t.string :ci_username, limit: 255
      t.text :trigger_token_ciphertext
      t.datetime :trigger_token_updated_at
    end

    change_table :tm_test_runs, bulk: true do |t|
      t.string :ci_trigger_status, limit: 16
      t.string :ci_trigger_url, limit: 1024
      t.text :ci_trigger_error
      t.datetime :ci_triggered_at
    end
  end
end
