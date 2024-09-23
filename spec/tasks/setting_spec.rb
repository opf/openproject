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

require "spec_helper"

RSpec.describe Rake::Task, :settings_reset do
  describe "setting:set" do
    let(:configuration_yml) do
      <<~YAML
        ---
          default:
            email_delivery_method: 'initial_file_value'
      YAML
    end

    include_context "rake" do
      let(:task_name) { "setting:set" }
    end

    it "saves the setting in database" do
      subject.invoke("email_delivery_method=something")
      Setting.clear_cache
      expect(Setting.find_by(name: "email_delivery_method")&.value).to eq(:something)
      expect(Setting.email_delivery_method).to eq(:something)
    end

    context "if setting is overridden from config/configuration.yml file" do
      before do
        stub_configuration_yml
        reset(:email_delivery_method)
      end

      it "saves the setting in database" do
        expect { subject.invoke("email_delivery_method=something") }
          .to change { Setting.find_by(name: "email_delivery_method")&.value }
          .from(nil)
          .to(:something)
      end

      it "keeps using the value from the file" do
        expect(Setting.email_delivery_method).to eq(:initial_file_value)
        expect { subject.invoke("email_delivery_method=something") }
          .not_to change(Setting, :email_delivery_method)
          .from(:initial_file_value)
      end
    end

    context "if setting is already set in database" do
      before do
        Setting.create!(name: "email_delivery_method", value: "initial_db_value")
      end

      it "updates the setting" do
        expect { subject.invoke("email_delivery_method=something") }
          .to change { Setting.find_by(name: "email_delivery_method")&.value }
          .from(:initial_db_value)
          .to(:something)
      end

      context "if setting is overridden from config/configuration.yml file" do
        before do
          stub_configuration_yml
          reset(:email_delivery_method)
        end

        it "updates the setting in database" do
          expect { subject.invoke("email_delivery_method=something") }
            .to change { Setting.find_by(name: "email_delivery_method")&.value }
                  .from(:initial_db_value)
                  .to(:something)
        end

        it "keeps using the value from the file" do
          expect(Setting.email_delivery_method).to eq(:initial_file_value)
          expect { subject.invoke("email_delivery_method=something") }
            .not_to change(Setting, :email_delivery_method)
                      .from(:initial_file_value)
        end
      end
    end
  end

  describe "setting:available_envs" do
    include_context "rake"

    it "displays all environment variables which can override settings values" do
      # just want to ensure the code does not raise any errors
      expect { subject.invoke }
        .to output(/OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO/).to_stdout
    end
  end
end
