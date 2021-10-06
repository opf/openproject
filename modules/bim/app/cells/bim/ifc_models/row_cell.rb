module Bim
  module IfcModels
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::AvatarHelper
      include ::Redmine::I18n

      def title
        if still_processing?
          model.title
        else
          link_to model.title,
                  bcf_project_ifc_model_path(model.project, model)
        end
      end

      def default?
        if model.is_default?
          op_icon 'icon icon-checkmark'
        end
      end

      def updated_at
        format_date(model.updated_at)
      end

      def uploader
        icon = avatar model.uploader, size: :mini
        icon + model.uploader.name
      end

      def processing
        if still_processing?
          I18n.t('ifc_models.processing_state.in_progress')
        else
          I18n.t('ifc_models.processing_state.completed')
        end
      end

      def still_processing?
        model.xkt_attachment.nil?
      end

      ###

      def button_links
        links = []

        # Seeded IFC models currently actually only have the XKT and NOT(!) the IFC original seeded
        if model.ifc_attachment
          links << download_link
        end

        if User.current.allowed_to?(:manage_ifc_models, model.project)
          links + [edit_link, delete_link]
        else
          links
        end
      end

      def delete_link
        link_to '',
                bcf_project_ifc_model_path(model.project, model),
                class: 'icon icon-delete',
                data: { confirm: I18n.t(:text_are_you_sure) },
                title: I18n.t(:button_delete),
                method: :delete
      end

      def download_link
        link_to '',
                ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(model.ifc_attachment.id),
                class: 'icon icon-download',
                title: I18n.t(:button_download)
      end

      def edit_link
        link_to '',
                edit_bcf_project_ifc_model_path(model.project, model),
                class: 'icon icon-edit',
                accesskey: accesskey(:edit),
                title: I18n.t(:button_edit)
      end
    end
  end
end
