require 'fastimage'

module ::Avatars
  class UpdateService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def replace(avatar)
      if avatar.nil?
        return ServiceResult.new(success: false).tap do |_result|
          return error_result(I18n.t(:empty_file_error))
        end
      end

      unless avatar.original_filename =~ /\.(jpe?g|gif|png)\z/i
        return error_result(I18n.t(:wrong_file_format))
      end

      image_data = FastImage.new avatar.path
      unless %i(jpeg jpg png gif).include? image_data.type
        return error_result(I18n.t(:wrong_file_format))
      end

      if image_data.content_length > 2.5.megabytes
        return error_result(I18n.t(:error_image_size))
      end

      if image_data.size.any? { |dim| dim > 128 }
        return error_result(I18n.t(:error_image_size))
      end

      @user.local_avatar_attachment = avatar
      ServiceResult.new(success: true, result: I18n.t(:message_avatar_uploaded))
    rescue StandardError => e
      Rails.logger.error "Failed to update avatar of user##{user.id}: #{e}"
      error_result(I18n.t(:error_image_upload))
    end

    def destroy
      current_attachment = @user.local_avatar_attachment
      if current_attachment && current_attachment.destroy
        @user.reload
        ServiceResult.new(success: true, result: I18n.t(:avatar_deleted))
      else
        error_result(I18n.t(:unable_to_delete_avatar))
      end
    rescue StandardError => e
      Rails.logger.error "Failed to delete avatar of user##{user.id}: #{e}"
      error_result(e.message)
    end

    private

    def error_result(message)
      ServiceResult.new(success: false).tap do |result|
        result.errors.add(:base, message)
      end
    end
  end
end
