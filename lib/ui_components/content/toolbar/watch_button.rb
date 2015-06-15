module UiComponents
  module Content
    class Toolbar
      class WatchButton < UiComponents::Content::Button
        attr_accessor :user, :object, :watch_text, :unwatch_text

        role :button

        def initialize(user, object, attributes = {})
          @user = user
          @object = object
          @watch_text = attributes.fetch :watch_text, I18n.t(:button_watch)
          @unwatch_text = attributes.fetch :unwatch_text, I18n.t(:button_unwatch)
          super attributes
        end

        private

        def watched?
          object.watched_by? user
        end

        def watch_options
          html_options.merge(
            data: {
              remote: true,
              method: method,
              watch_text: watch_text,
              unwatch_text: unwatch_text,
              watch_icon: :'watch-1',
              unwatch_icon: :'not-watch',
              watch_path: watch_path(object, false),
              unwatch_path: watch_path(object, true),
              watch_method: :post,
              unwatch_method: :delete
            }
          ).merge(href: watch_path(object, watched?))
        end

        def icon_class
          watched? ? %w(icon-not-watch) : %w(icon-watch-1)
        end

        def icon_and_text
          capture do
            concat content_tag :i, '', class: %w(button--icon) + icon_class
            concat content_tag :span, text, class: %w(button--text)
          end
        end

        def method
          watched? ? :delete : :post
        end

        def text
          watched? ? unwatch_text : watch_text
        end

        def watch_path(object, watched)
          path_name = watched ? 'unwatch_path' : 'watch_path'
          send path_name, object_type: object.class.to_s.underscore.pluralize,
                                      object_id: object.id
        end

        def default_strategy
          -> {
            content_tag :a, icon_and_text, watch_options
          }
        end
      end
    end
  end
end
