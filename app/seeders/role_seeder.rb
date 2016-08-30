module BasicData
  module Documents
    module RoleSeeder
      def member
        super.tap do |member|
          member[:permissions].concat %i(
            view_documents
            manage_documents
          )
        end
      end

      def reader
        super.tap do |reader|
          reader[:permissions].concat %i(
            view_documents
          )
        end
      end
    end

    BasicData::RoleSeeder.prepend BasicData::Documents::RoleSeeder
  end
end
