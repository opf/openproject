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
        icon = avatar model.uploader, class: 'avatar-mini'
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
        model.xkt_attachment.nil? || model.metadata_attachment.nil?
      end

      ###

      def button_links
        if User.current.allowed_to?(:manage_ifc_models, model.project)
          [edit_link, delete_link]
        else
          []
        end
      end

      def delete_link
        link_to '',
                bcf_project_ifc_model_path(model.project, model),
                class: 'icon icon-delete',
                data: { confirm: I18n.t(:text_are_you_sure) },
                method: :delete
      end

      def edit_link
        link_to '',
                edit_bcf_project_ifc_model_path(model.project, model),
                class: 'icon icon-edit',
                accesskey: accesskey(:edit)
      end
    end
  end
end
