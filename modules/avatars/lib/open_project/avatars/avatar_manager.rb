module OpenProject
  module Avatars
    module AvatarManager
      class << self
        def settings
          (Setting.plugin_openproject_avatars || {}).with_indifferent_access
        end

        def gravatar_enabled?
          val = settings[:enable_gravatars]
          ActiveModel::Type::Boolean.new.cast(val)
        end

        def local_avatars_enabled?
          val = settings[:enable_local_avatars]
          ActiveModel::Type::Boolean.new.cast(val)
        end

        def available_types(principal)
          types = %w[initials]
          types.unshift("image") if local_avatars_enabled?
          types.unshift("gravatar") if principal.is_a?(User) && gravatar_enabled?
          types
        end

        def avatar_type_for(principal)
          types = available_types(principal)
          return types.first if types.one?
          return default_avatar_type_for(principal) if principal.avatar_type.blank?

          types.include?(principal.avatar_type) ? principal.avatar_type : "initials"
        end

        private

        def default_avatar_type_for(principal)
          return "image" if local_avatars_enabled? && principal.local_avatar_attachment
          return "initials" if principal.avatar_text.present?
          return "gravatar" if principal.is_a?(User) && gravatar_enabled?

          "initials"
        end
      end
    end
  end
end
