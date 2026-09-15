module Bim
  module IfcModels
    class RowComponent < ::RowComponent
      property :created_at

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
          helpers.op_icon "icon icon-checkmark"
        end
      end

      def updated_at
        helpers.format_date(model.updated_at)
      end

      def uploader
        icon = helpers.avatar model.uploader, size: :mini
        icon + model.uploader.name
      end

      def processing
        content_tag(:div, class: "ifc-models--processing-container", id: "ifc-model-#{model.id}-status") do
          content = content_tag(:div, class: "ifc-models--status-row") do
            status_content = content_tag(:span,
                                         I18n.t("ifc_models.conversion_status.#{model.conversion_status}"),
                                         class: "ifc-models--conversion-status")

            if model.conversion_status == "processing" && model.conversion_progress.present?
              status_content << content_tag(:span, " (#{progress_percentage}%)", class: "ifc-models--progress-percentage")
              if model.conversion_stage.present?
                status_content << content_tag(:span, " - #{stage_name}", class: "ifc-models--stage-name")
              end
            end

            if model.conversion_error_message
              status_content << ": ".html_safe
              status_content << content_tag(:span,
                                           model.conversion_error_message,
                                           class: "ifc-models--conversion-status-error",
                                           title: model.conversion_error_message)
            end

            status_content
          end

          # Add progress bar for processing status
          if model.conversion_status == "processing"
            content << content_tag(:div, class: "ifc-models--progress-bar-container") do
              content_tag(:div,
                         "",
                         class: "ifc-models--progress-bar",
                         style: "width: #{progress_percentage}%;")
            end
          end

          # Add warnings section if present
          if has_warnings?
            content << content_tag(:div, class: "ifc-models--warnings") do
              warning_content = content_tag(:span, "#{warnings.count} warnings", class: "ifc-models--warning-count")
              warning_content << content_tag(:ul, class: "ifc-models--warning-list") do
                warnings.map do |warning|
                  content_tag(:li, warning["message"], class: "ifc-models--warning-item")
                end.join.html_safe
              end
            end
          end

          content
        end
      end

      def progress_percentage
        model.conversion_progress.to_i
      end

      def stage_name
        return "" unless model.conversion_stage.present?

        case model.conversion_stage
        when "validation"
          "Validation"
        when "ifc_to_dae"
          "IFC to DAE"
        when "dae_to_gltf"
          "DAE to glTF"
        when "gltf_to_xkt"
          "glTF to XKT"
        when "enhanced_metadata"
          "Metadata extraction"
        else
          model.conversion_stage.humanize
        end
      end

      def warnings
        return [] unless model.conversion_logs.present?

        model.conversion_logs.select { |log| log["level"] == "warning" }
      end

      def has_warnings?
        warnings.any?
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

        if User.current.allowed_in_project?(:manage_ifc_models, model.project)
          links.push(edit_link, delete_link)
        else
          links
        end
      end

      def delete_link
        link_to "",
                bcf_project_ifc_model_path(model.project, model),
                class: "icon icon-delete",
                data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
                title: I18n.t(:button_delete)
      end

      def download_link
        link_to "",
                API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(model.ifc_attachment&.id),
                class: "icon icon-download",
                title: I18n.t(:button_download),
                download: true
      end

      def edit_link
        link_to "",
                edit_bcf_project_ifc_model_path(model.project, model),
                class: "icon icon-edit",
                accesskey: helpers.accesskey(:edit),
                title: I18n.t(:button_edit)
      end
    end
  end
end
