module WillPaginate
  module I18n
    def self.locale_dir
      File.expand_path('../locale', __FILE__)
    end

    def self.load_path
      Dir["#{locale_dir}/*.{rb,yml}"]
    end

    def will_paginate_translate(keys, options = {}, &block)
      if defined? ::I18n
        defaults = Array(keys).dup
        defaults << block if block_given?
        ::I18n.translate(defaults.shift, **options.merge(:default => defaults, :scope => :will_paginate))
      else
        key = Array === keys ? keys.first : keys
        yield key, options
      end
    end
  end
end
