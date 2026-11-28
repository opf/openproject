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

require "shrine/storage/memory"

class WithDirectUploads
  attr_reader :context

  def initialize(context)
    @context = context
  end

  ##
  # We need this so calls to rspec mocks (allow, expect etc.) will work here as expected.
  def method_missing(method, *, &)
    if context.respond_to?(method)
      context.send(method, *, &)
    else
      super
    end
  end

  def before(example)
    stub_config example

    stub_frontend redirect: redirect?(example) if stub_frontend?(example)
    allow(OpenProject::Configuration).to receive(:direct_uploads?).and_return(true)
    stub_shrine_storage
  end

  def stub_shrine_storage
    allow(AttachmentShrine).to receive(:storage_for).and_call_original
    operations = %i[upload open exists? delete]
    %i[s3 store].each do |name|
      storage = AttachmentShrine.storage_for(name)
      memory = Shrine::Storage::Memory.new
      operations.each do |operation|
        allow(storage).to receive(operation) { |*args, **opts| memory.public_send(operation, *args, **opts) }
      end
      allow(AttachmentShrine).to receive(:storage_for).with(name).and_return(storage)
    end
  end

  def stub_frontend?(example)
    example.metadata[:js]
  end

  def redirect?(example)
    example.metadata[:with_direct_uploads] == :redirect
  end

  def around(example)
    example.metadata[:javascript_driver] = example.metadata[:driver] = :chrome_billy
    example.run
  end

  def stub_frontend(redirect: false)
    stub_chrome_background_requests

    # The stubbed S3 endpoint below accepts uploads without storing them, so the staged file
    # the uploaded callback checks for never exists.
    allow_any_instance_of(DirectFogUploader).to receive(:readable?).and_return(true) # rubocop:disable RSpec/AnyInstance

    proxy.stub("https://#{OpenProject::Configuration.remote_storage_upload_host}:443/", method: "options").and_return(
      headers: {
        "Access-Control-Allow-Methods" => "POST",
        "Access-Control-Allow-Origin" => "*"
      },
      code: 200
    )

    if redirect
      stub_with_redirect
    else
      # use status response instead of redirect by default
      stub_with_status
    end
  end

  def stub_with_redirect
    proxy
      .stub("https://#{OpenProject::Configuration.remote_storage_upload_host}:443/", method: "post")
      .and_return(Proc.new do |_params, _headers, body, _url, _method|
        key = body.scan(/key"\s*([^\s]+)\s/m).flatten.first
        redirect_url = body.scan(/success_action_redirect"\s*(http[^\s]+)\s/m).flatten.first
        ok = body.downcase.include?("x-amz-signature") # check that the expected post to AWS was made with the form fields

        {
          code: ok ? 302 : 403,
          headers: {
            "Location" => ok ? append_key_query_param(redirect_url, key) : nil,
            "Access-Control-Allow-Methods" => "POST",
            "Access-Control-Allow-Origin" => "*"
          }
        }
      end)
  end

  def stub_chrome_background_requests
    [
      %r{\Ahttp://clients2\.google\.com(?::80)?/},
      %r{\Ahttps://accounts\.google\.com(?::443)?/},
      %r{\Ahttps://www\.google\.com(?::443)?/},
      %r{\Ahttps://content-autofill\.googleapis\.com(?::443)?/},
      %r{\Ahttps://optimizationguide-pa\.googleapis\.com(?::443)?/},
      %r{\Ahttps://update\.googleapis\.com(?::443)?/},
      %r{\Ahttps://android\.clients\.google\.com(?::443)?/}
    ].each do |url_pattern|
      %w[get post].each do |method|
        proxy.stub(url_pattern, method:).and_return(code: 204, headers: {})
      end
    end
  end

  def append_key_query_param(redirect_url, key)
    delimiter = redirect_url.include?("?") ? "&" : "?"
    "#{redirect_url}#{delimiter}key=#{CGI.escape(key)}"
  end

  def stub_with_status
    proxy
      .stub("https://#{OpenProject::Configuration.remote_storage_upload_host}:443/", method: "post")
      .and_return(Proc.new do |_params, _headers, body, _url, _method|
        {
          code: body.downcase.include?("x-amz-signature") ? 201 : 403,
          headers: {
            "Access-Control-Allow-Methods" => "POST",
            "Access-Control-Allow-Origin" => "*"
          }
        }
      end)
  end

  def stub_config(example)
    WithConfig.new(context).before example, config
  end

  def config
    {
      attachments_storage: :fog,
      fog: {
        directory: MockCarrierwave.bucket,
        credentials: MockCarrierwave.credentials
      }
    }
  end
end

RSpec.configure do |config|
  config.before do |example|
    next unless example.metadata[:with_direct_uploads]

    WithDirectUploads.new(self).before example
  end

  config.around do |example|
    enabled = example.metadata[:with_direct_uploads]

    if enabled
      WithDirectUploads.new(self).around example
    else
      example.run
    end
  end
end
