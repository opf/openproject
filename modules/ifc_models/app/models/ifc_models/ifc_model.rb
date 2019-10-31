module IFCModels
  class IFCModel < ActiveRecord::Base
    acts_as_attachable delete_permission: :manage_ifc_models

    has_one :project
    belongs_to :uploader, class_name: 'User', foreign_key: 'uploader_id'

    def ifc_attachment
      attachments.first
    end

    def xkt_attachment
      attachments.second
    end

    def delete_ifc_attachment
      delete_xkt_attachment
      ifc_attachment&.destroy
    end

    def delete_xkt_attachment
      xkt_attachment&.destroy
    end
  end
end
