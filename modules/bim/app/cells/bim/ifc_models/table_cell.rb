module Bim
  module IfcModels
    class TableCell < ::TableCell
      include ::IconsHelper
      columns :title, :default?, :created_at, :updated_at, :uploader, :processing

      def initial_sort
        %i[created_at asc]
      end

      def sortable?
        false
      end

      def inline_create_link
        link_to(new_bcf_project_ifc_model_path,
                class: 'wp-inline-create--add-link',
                title: I18n.t('ifc_models.label_new_ifc_model')) do
          op_icon('icon icon-add')
        end
      end

      def empty_row_message
        I18n.t 'ifc_models.no_results'
      end

      def headers
        [
          ['title', caption: IfcModel.human_attribute_name(:title)],
          ['is_default', caption: IfcModel.human_attribute_name(:is_default)],
          ['created_at', caption: IfcModel.human_attribute_name(:created_at)],
          ['updated_at', caption: IfcModel.human_attribute_name(:updated_at)],
          ['uploader', caption: IfcModel.human_attribute_name(:uploader)],
          ['processing', caption: I18n.t('ifc_models.processing_state.label')]
        ]
      end
    end
  end
end
