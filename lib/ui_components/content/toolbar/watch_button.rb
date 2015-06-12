module UiComponents
  module Content
    class Toolbar
      class WatchButton < UiComponents::Content::Button
        private

        def default_strategy
          -> {
            content_tag :a, text, options
          }
        end
      end
    end
  end
end
