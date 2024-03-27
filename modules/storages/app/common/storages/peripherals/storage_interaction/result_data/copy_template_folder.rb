module Storages
  module Peripherals
    module StorageInteraction
      module ResultData
        CopyTemplateFolder = Data.define(:id, :polling_url, :requires_polling) do
          def requires_polling? = !!requires_polling
        end
      end
    end
  end
end
