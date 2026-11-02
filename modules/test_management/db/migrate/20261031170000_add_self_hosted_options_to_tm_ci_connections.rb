# frozen_string_literal: true

# Self-hosted Git and CI (0015):
# - ca_certificate: optional PEM bundle (one or more CA certificates) that OpenProject trusts in
#   addition to the system store for this connection's outbound calls (internal / corporate CA).
#   Public data, not a secret.
# - inbound_only: OpenProject never calls this server (one-way networks: CI -> OpenProject only).
#   "Check connection", the trigger and pull-request sources are off; "Run in CI" prepares the
#   run and shows the values to start the pipeline by hand.
# - server_version: version reported by the last successful "Check connection".
class AddSelfHostedOptionsToTmCiConnections < ActiveRecord::Migration[8.0]
  def change
    change_table :tm_ci_connections, bulk: true do |t|
      t.text :ca_certificate
      t.boolean :inbound_only, null: false, default: false
      t.string :server_version, limit: 64
    end
  end
end
