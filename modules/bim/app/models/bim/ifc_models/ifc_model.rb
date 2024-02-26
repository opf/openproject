module Bim
  module IfcModels
    class IfcModel < ApplicationRecord
      # Note: rails 7.1 breaks the class' ancestor chain, if it fails to infer the enum attribute's
      # type. We reference the Project class in migrations prior to the `conversion_status` column being added
      # to the database, which leads to rails failing to infer the enum's type.
      # The `conversion_status`'s type needs to be declared so rails will do the correct type inference and
      # not break the ancestor chain. Once this is fixed in rails, we can remove it.
      attribute :conversion_status, :integer

      enum conversion_status: {
        pending: 0,
        processing: 1,
        completed: 2,
        error: 3
      }.freeze

      acts_as_attachable delete_permission: :manage_ifc_models,
                         add_permission: :manage_ifc_models,
                         view_permission: :view_ifc_models

      belongs_to :project
      belongs_to :uploader, class_name: 'User'

      validates :title, presence: true
      validates :project, presence: true

      scope :defaults, -> { where(is_default: true) }

      %i(ifc xkt).each do |name|
        define_method :"#{name}_attachment" do
          get_attached_type(name)
        end

        define_method :"#{name}_attachment=" do |file|
          if name == :ifc
            # Also delete xkt
            delete_attachment :xkt
          end

          delete_attachment name
          filename = file.respond_to?(:original_filename) ? file.original_filename : File.basename(file.path)
          call = ::Attachments::CreateService
            .bypass_whitelist(user: User.current)
            .call(file:, container: self, filename:, description: name)

          call.on_failure { Rails.logger.error "Failed to add #{name} attachment: #{call.message}" }
        end
      end

      def converted?
        xkt_attachment.present?
      end

      private

      ##
      # Delete the given named description
      def get_attached_type(key)
        if attachments.loaded?
          attachments.detect { |a| a.description == key.to_s && !a.marked_for_destruction? }
        else
          attachments.find_by_description(key.to_s)
        end
      end

      ##
      # Delete the given named description
      def delete_attachment(key)
        get_attached_type(key)&.destroy
      end
    end
  end
end
