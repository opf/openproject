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

        def path
          "#{@storage.group_folder}/#{@project.name.tr('/', '|')} (#{@project.id})/"
        end

        def location
          path
        end
      end
    end
  end
end
