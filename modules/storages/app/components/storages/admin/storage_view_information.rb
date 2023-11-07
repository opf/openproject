# frozen_string_literal: true

module Storages::Admin
  module StorageViewInformation
    private

    def editable_storage?
      storage.persisted?
    end

    def storage_description
      [storage.short_provider_type.capitalize,
       storage.name,
       storage.host].compact.join(' - ')
    end

    def configuration_check_label_for(config)
      if storage.configuration_checks[config.to_sym]
        status_label(I18n.t('storages.label_connected'), scheme: :success, test_selector: "label-#{config}-status")
      else
        status_label(I18n.t('storages.label_incomplete'), scheme: :attention, test_selector: "label-#{config}-status")
      end
    end

    def status_label(label, scheme:, test_selector:)
      render(Primer::Beta::Label.new(scheme:, test_selector:)) { label }
    end

    def automatically_managed_project_folders_status_label
      test_selector = 'label-managed-project-folders-status'

      if storage.automatically_managed?
        status_label(I18n.t('storages.label_active'), scheme: :success, test_selector:)
      elsif storage.automatic_management_unspecified?
        status_label(I18n.t('storages.label_incomplete'), scheme: :attention, test_selector:)
      else
        status_label(I18n.t('storages.label_inactive'), scheme: :secondary, test_selector:)
      end
    end

    def openproject_oauth_client_description
      return unless storage.oauth_application

      "#{I18n.t('storages.label_oauth_client_id')}: #{storage.oauth_application.uid}"
    end

    def provider_oauth_client_description
      if storage.oauth_client
        "#{I18n.t('storages.label_oauth_client_id')}: #{storage.oauth_client.client_id}"
      else
        I18n.t("storages.configuration_checks.oauth_client_incomplete.#{storage.short_provider_type}")
      end
    end
  end
end
