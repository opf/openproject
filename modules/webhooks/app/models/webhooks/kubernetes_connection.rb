# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Webhooks
  class KubernetesConnection < ApplicationRecord
    SERVICE_ACCOUNT_DIR = "/var/run/secrets/kubernetes.io/serviceaccount"

    enum :auth_mode,
         { in_cluster: "in_cluster", bearer_token: "bearer_token", client_certificate: "client_certificate" },
         validate: true

    has_many :scripts, class_name: "::Webhooks::KubernetesScript", dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :api_url, presence: true, url: true, unless: :in_cluster?
    validates :namespace, presence: true, unless: :in_cluster?
    validates :token, presence: true, if: :bearer_token?
    validates :client_cert, :client_key, presence: true, if: :client_certificate?
    validates :openproject_url, url: true, allow_blank: true

    def effective_openproject_url
      openproject_url.presence&.delete_suffix("/") ||
        "#{Setting.protocol}://#{Setting.host_name}#{OpenProject::Configuration.rails_relative_url_root}"
    end

    def request(method, path, body: nil, raw: false)
      uri = URI.join(base_url, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 15
      configure_tls(http) if http.use_ssl?

      req = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
      req["Accept"] = "application/json"
      req["Authorization"] = "Bearer #{effective_token}" if effective_token.present?
      if body
        req["Content-Type"] = "application/json"
        req.body = body.to_json
      end

      response = http.request(req)
      return [response.code.to_i, response.body.to_s.force_encoding(Encoding::UTF_8).scrub] if raw

      parsed = response.body.present? ? JSON.parse(response.body) : {}
      [response.code.to_i, parsed]
    rescue JSON::ParserError
      [response.code.to_i, { "message" => response.body.to_s.truncate(500) }]
    end

    def test_connection
      status, version = request(:get, "/version")
      return [false, "GET /version returned #{status}"] unless status == 200

      status, body = request(:get, "/apis/batch/v1/namespaces/#{effective_namespace}/jobs?limit=1")
      if status == 200
        [true, "Kubernetes #{version['gitVersion']}, jobs in namespace '#{effective_namespace}' are accessible."]
      else
        [false, "Kubernetes #{version['gitVersion']} reachable, but listing jobs failed (#{status}): #{body['message']}"]
      end
    rescue StandardError => e
      [false, "#{e.class}: #{e.message}"]
    end

    def base_url
      if in_cluster?
        "https://#{ENV.fetch('KUBERNETES_SERVICE_HOST')}:#{ENV.fetch('KUBERNETES_SERVICE_PORT', '443')}"
      else
        api_url
      end
    end

    def effective_namespace
      if in_cluster? && namespace.blank?
        File.read(File.join(SERVICE_ACCOUNT_DIR, "namespace")).strip
      else
        namespace
      end
    end

    private

    # The projected service account token is rotated by the kubelet, so it is read on every request.
    def effective_token
      if in_cluster?
        File.read(File.join(SERVICE_ACCOUNT_DIR, "token")).strip
      elsif bearer_token?
        token
      end
    end

    def effective_ca_cert
      in_cluster? ? File.read(File.join(SERVICE_ACCOUNT_DIR, "ca.crt")) : ca_cert
    end

    def configure_tls(http)
      http.verify_mode = verify_tls? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

      if effective_ca_cert.present?
        store = OpenSSL::X509::Store.new
        OpenSSL::X509::Certificate.load(effective_ca_cert).each { store.add_cert(it) }
        http.cert_store = store
      end

      if client_certificate?
        http.cert = OpenSSL::X509::Certificate.new(client_cert)
        http.key = OpenSSL::PKey.read(client_key)
      end
    end
  end
end
