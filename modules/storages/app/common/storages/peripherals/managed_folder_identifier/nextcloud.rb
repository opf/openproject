# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Peripherals
    module ManagedFolderIdentifier
      class Nextcloud
        def initialize(project_storage)
          @storage = project_storage.storage
          @project = project_storage.project
        end

        def name
          "#{@project.name.tr('/', '|')} (#{@project.id})"
        end

        def path
          "/#{@storage.group_folder}/#{name}/"
        end

        def location
          path
        end
      end
    end
  end
end
