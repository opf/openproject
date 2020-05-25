require File.dirname(__FILE__) + '/../../spec_helper'
require 'open_project/auth_saml'

describe OpenProject::AuthSaml do
  before do
    OpenProject::AuthSaml.reload_configuration!
  end

  after do
    OpenProject::AuthSaml.reload_configuration!
  end

  describe ".configuration" do
    let(:config) do
      # the `configuration` method is cached to avoid
      # loading the SAML file more than once
      # thus remove any cached value here
      OpenProject::AuthSaml.remove_instance_variable('@saml_settings')
      OpenProject::AuthSaml.configuration
    end


    context(
      "with configuration",
      with_config: {
        saml: {
          my_saml: {
            name: "saml",
            display_name: "My SSO"
          }
        }
      }
    ) do
      it "contains the configuration from OpenProject::Configuration (or settings.yml) by default" do
        expect(config[:my_saml][:name]).to eq 'saml'
        expect(config[:my_saml][:display_name]).to eq 'My SSO'
      end

      context(
        "with settings override from database",
        with_settings: {
          plugin_openproject_auth_saml: {
            providers: {
              my_saml: {
                display_name: "Your SSO"
              },
              new_saml: {
                name: "new_saml",
                display_name: "Another SAML"
              }
            }
          }
        }
      ) do
        it "overrides the existing configuration where defined" do
          expect(config[:my_saml][:name]).to eq 'saml'
          expect(config[:my_saml][:display_name]).to eq 'Your SSO'
        end

        it "defines new providers if given" do
          expect(config[:new_saml][:name]).to eq 'new_saml'
          expect(config[:new_saml][:display_name]).to eq 'Another SAML'
        end
      end
    end
  end
end
