# frozen_string_literal: true

module Storages::Admin
  module StorageViewInformation
    private

    def editable_storage?
      storage.persisted?
    end

    def storage_description
      [I18n.t("storages.provider_types.#{storage.short_provider_type}.name"),
       storage.name,
       storage.host].compact.join(" - ")
    end

    def configuration_check_label
      if storage.provider_type_nextcloud?
        configuration_check_label_for(:host_name_configured)
      elsif storage.provider_type_one_drive?
        configuration_check_label_for(:name_configured, :storage_tenant_drive_configured)
      end
    end

    def configuration_check_label_for(*configs)
      # do not show the status label, if storage is completely empty (initial state)
      return if storage.configuration_checks.values.none?

      if storage.configuration_checks.slice(*configs.map(&:to_sym)).values.all?
        status_label(I18n.t("storages.label_completed"), scheme: :success, test_selector: "label-#{configs.join('-')}-status")
      else
        status_label(I18n.t("storages.label_incomplete"), scheme: :attention, test_selector: "label-#{configs.join('-')}-status")
      end
    end

    def status_label(label, scheme:, test_selector:)
      render(Primer::Beta::Label.new(scheme:, test_selector:)) { label }
    end

    def automatically_managed_project_folders_status_label
      # do not show the status label, if storage is completely empty (initial state)
      return if storage.configuration_checks.values.none?

      test_selector = "label-managed-project-folders-status"

      if storage.automatic_management_enabled?
        status_label(I18n.t("storages.label_active"), scheme: :success, test_selector:)
      elsif storage.automatic_management_unspecified?
        status_label(I18n.t("storages.label_incomplete"), scheme: :attention, test_selector:)
      else
        status_label(I18n.t("storages.label_inactive"), scheme: :secondary, test_selector:)
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

    def provider_redirect_uri_description
      if storage.oauth_client
        "#{I18n.t('storages.label_uri')}: #{storage.oauth_client.redirect_uri}"
      else
        I18n.t("storages.configuration_checks.redirect_uri_incomplete.#{storage.short_provider_type}")
      end
    end
  end
end
