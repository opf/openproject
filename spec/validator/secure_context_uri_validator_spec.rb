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

# require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require "spec_helper"

RSpec.describe SecureContextUriValidator do
  let(:host) { nil }
  let(:model_class) do
    Class.new do
      include ActiveModel::Validations
      def self.model_name
        ActiveModel::Name.new(self, nil, "ValidatedModel")
      end

      attr_accessor :host

      validates :host, secure_context_uri: true
    end
  end
  let(:model_instance) { model_class.new.tap { |instance| instance.host = host } }

  before { model_instance.validate }

  context "with empty URI" do
    ["", " ", nil].each do |uri|
      describe "when URI is '#{uri}'" do
        let(:host) { uri }

        it "adds an :invalid_url error" do
          expect(model_instance.errors).to include(:host)
          expect(model_instance.errors.first.type).to be :invalid_url
        end
      end
    end
  end

  context "with invalid URI" do
    %w(some_string http://<>ample.com).each do |uri|
      describe "when URI is '#{uri}'" do
        let(:host) { uri }

        it "adds an :invalid_url error" do
          expect(model_instance.errors).to include(:host)
          expect(model_instance.errors.first.type).to be :invalid_url
        end
      end
    end
  end

  context "with valid URI" do
    context "when host is missing" do
      let(:host) { "https://" }

      it "adds an :invalid_url error" do
        expect(model_instance.errors).to include(:host)
        expect(model_instance.errors.first.type).to be :invalid_url
      end
    end

    context "when not providing a Secure Context" do
      %w{http://128.0.0.1 http://foo.com http://[::2]}.each do |uri|
        describe "when URI is '#{uri}'" do
          let(:host) { uri }

          it "adds a :url_not_secure_context error" do
            expect(model_instance.errors).to include(:host)
            expect(model_instance.errors.first.type).to be :url_not_secure_context
          end
        end
      end
    end

    context "when providing a Secure Context" do
      context "with a loopback IP" do
        %w{http://127.0.0.1 http://127.1.1.1}.each do |uri|
          describe "when URI is '#{uri}'" do
            let(:host) { uri }

            it "does not add an error" do
              expect(model_instance.errors).not_to include(:host)
            end
          end
        end
      end

      context "with a domain name" do
        %w(https://example.com http://localhost http://.localhost http://foo.localhost. http://foo.localhost).each do |uri|
          describe "when URI is '#{uri}'" do
            let(:host) { uri }

            it "does not add an error" do
              expect(model_instance.errors).not_to include(:host)
            end
          end
        end
      end

      context "with IPV6 loopback URI" do
        let(:host) { "http://[::1]" }

        it "does not add an error" do
          expect(model_instance.errors).not_to include(:host)
        end
      end
    end
  end
end
