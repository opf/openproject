module ::Avatars
  class AvatarController < ::ApplicationController
    before_action :ensure_enabled
    before_action :find_avatar

    no_authorization_required! :show

    def show
      send_file @avatar.diskfile,
                filename: filename_for_content_disposition(@avatar.filename),
                type: @avatar.content_type,
                disposition: "inline"
    rescue StandardError => e
      Rails.logger.error "Failed to render avatar for #{@avatar&.id}: #{e.message}"
      head :not_found
    end

    def breadcrumb_items
      [{ href: admin_index_path, text: t("label_administration") },
       { href: admin_settings_users_path, text: t(:label_user_settings) },
       @plugin.name]
    end

    helper_method :breadcrumb_items

    private

    def find_avatar
      @avatar = User.get_local_avatar(params[:id])

      unless @avatar
        head :not_found
        false
      end
    end

    def ensure_enabled
      unless ::OpenProject::Avatars::AvatarManager.local_avatars_enabled?
        head :not_found
        false
      end
    end
  end
end
