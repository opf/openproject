# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Peripherals
    module ManagedFolderIdentifier
      class OneDrive
        CHARACTER_BLOCKLIST = /[\\<>+?:"|\/]/

        def initialize(project_storage)
          @project_storage = project_storage
          @project = project_storage.project
        end

        def name
          path
        end

        def path
          "#{@project.name.gsub(CHARACTER_BLOCKLIST, '_')} (#{@project.id})"
        end

        def location
          @project_storage.project_folder_id
        end
      end
    end
  end
end
