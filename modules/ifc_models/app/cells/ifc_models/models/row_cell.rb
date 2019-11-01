module IFCModels
  module Models
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::AvatarHelper
      include ::Redmine::I18n

      def title
        link_to model.title,
                ifc_models_project_ifc_model_path(model.project, model)
      end

      def updated_at
        format_date(model.updated_at)
      end

      def uploader
        icon = avatar model.uploader, class: 'avatar-mini'
        icon + model.uploader.name
      end

      def processing
        if model.xkt_attachment.present?
          I18n.t('ifc_models.processing_state.completed')
        else
          I18n.t('ifc_models.processing_state.in_progress')
        end
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
                ifc_models_project_ifc_model_path(model.project, model),
                class: 'icon icon-delete',
                data: {confirm: I18n.t(:text_are_you_sure)},
                method: :delete
      end

      def edit_link
        link_to '',
                edit_ifc_models_project_ifc_model_path(model.project, model),
                class: 'icon icon-edit',
                accesskey: accesskey(:edit)
      end

      def deletion_blocked?
        return false if table.admin_table?

        device.default && table.enforced?
      end
    end
  end
end
