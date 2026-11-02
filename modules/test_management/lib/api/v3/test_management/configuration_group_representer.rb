# frozen_string_literal: true

module API
  module V3
    module TestManagement
      class ConfigurationGroupRepresenter < ::API::Decorators::Single
        link :self do
          { href: api_v3_paths.test_management_configuration_group(represented.id), title: represented.name }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        property :id
        property :name
        property :configurations,
                 exec_context: :decorator,
                 getter: ->(*) {
                   represented.configurations.ordered.map do |config|
                     {
                       id: config.id,
                       name: config.name,
                       _type: "TestManagementConfiguration",
                       _links: {
                         self: { href: api_v3_paths.test_management_configuration(config.id) }
                       }
                     }
                   end
                 }

        def _type = "TestManagementConfigurationGroup"
      end
    end
  end
end
