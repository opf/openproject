require "i18n"

module FriendlyId

=begin

## Translating Slugs Using Simple I18n

The {FriendlyId::SimpleI18n SimpleI18n} module adds very basic i18n support to
FriendlyId.

In order to use this module, your model must have a slug column for each locale.
By default FriendlyId looks for columns named, for example, "slug_en",
"slug_es", etc. The first part of the name can be configured by passing the
`:slug_column` option if you choose. Note that the column for the default locale
must also include the locale in its name.

This module is most suitable to applications that need to support few locales.
If you need to support two or more locales, you may wish to use the
friendly_id_globalize gem instead.

### Example migration

    def self.up
      create_table :posts do |t|
        t.string :title
        t.string :slug_en
        t.string :slug_es
        t.text   :body
      end
      add_index :posts, :slug_en
      add_index :posts, :slug_es
    end

### Finds

Finds will take into consideration the current locale:

    I18n.locale = :es
    Post.friendly.find("la-guerra-de-las-galaxias")
    I18n.locale = :en
    Post.friendly.find("star-wars")

To find a slug by an explicit locale, perform the find inside a block
passed to I18n's `with_locale` method:

    I18n.with_locale(:es) do
      Post.friendly.find("la-guerra-de-las-galaxias")
    end

### Creating Records

When new records are created, the slug is generated for the current locale only.

### Translating Slugs

To translate an existing record's friendly_id, use
{FriendlyId::SimpleI18n::Model#set_friendly_id}. This will ensure that the slug
you add is properly escaped, transliterated and sequenced:

    post = Post.create :name => "Star Wars"
    post.set_friendly_id("La guerra de las galaxias", :es)

If you don't pass in a locale argument, FriendlyId::SimpleI18n will just use the
current locale:

    I18n.with_locale(:es) do
      post.set_friendly_id("La guerra de las galaxias")
    end
=end
  module SimpleI18n

    # FriendlyId::Config.use will invoke this method when present, to allow
    # loading dependent modules prior to overriding them when necessary.
    def self.setup(model_class)
      model_class.friendly_id_config.use :slugged
    end

    def self.included(model_class)
      model_class.class_eval do
        friendly_id_config.class.send :include, Configuration
        include Model
      end
    end

    module Model
      def set_friendly_id(text, locale = nil)
        I18n.with_locale(locale || I18n.locale) do
          set_slug(normalize_friendly_id(text))
        end
      end

      def slug=(value)
        super
        write_attribute friendly_id_config.slug_column, value
      end
    end

    module Configuration
      def slug_column
        "#{super}_#{I18n.locale}"
      end
    end
  end
end
