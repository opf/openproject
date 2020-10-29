module Cell
  module Helper
    # Delegate all asset-related helpers to the global helpers instance.
    # This is the cleanest solution to leverage Rails' asset management and
    # doesn't pollute your cell with weird asset modules from Rails.
    module AssetHelper
      # Extend if we forgot anything.
      # This delegates asset helpers to the global Rails helper instance.

      # http://api.rubyonrails.org/classes/ActionView/Helpers/AssetUrlHelper.html
      %w{
        javascript_include_tag
        stylesheet_link_tag

        asset_path
        asset_url
        image_tag
        video_tag
        audio_path
        audio_url
        compute_asset_extname
        compute_asset_host
        compute_asset_path
        favicon_link_tag
        font_path
        font_url
        image_path
        image_url
        javascript_path
        javascript_url
        path_to_asset
        path_to_audio
        path_to_font
        path_to_image
        path_to_javascript
        path_to_stylesheet
        path_to_video
        stylesheet_path
        stylesheet_url
        url_to_asset
        url_to_audio
        url_to_font
        url_to_image
        url_to_javascript
        url_to_stylesheet
        url_to_video
        video_path
        video_url
      }.each do |method|
        define_method(method) do |*args|
          ::ActionController::Base.helpers.send(method, *args)
        end
      end
    end # AssetHelper
  end
end
