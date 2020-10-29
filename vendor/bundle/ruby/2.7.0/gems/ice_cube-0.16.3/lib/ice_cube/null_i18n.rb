require 'yaml'

module IceCube
  module NullI18n
    def self.t(key, options = {})
      base = key.to_s.split('.').reduce(config) { |hash, current_key| hash[current_key] }

      base = base[options[:count] == 1 ? "one" : "other"] if options[:count]

      case base
      when Hash
        base.each_with_object({}) do |(k, v), hash|
          hash[k.is_a?(String) ? k.to_sym : k] = v
        end
      when Array
        base.each_with_index.each_with_object({}) do |(v, k), hash|
          hash[k] = v
        end
      else
        return base unless base.include?('%{')
        base % options
      end
    end

    def self.l(date_or_time, options = {})
      return date_or_time.strftime(options[:format]) if options[:format]
      date_or_time.strftime(t('ice_cube.date.formats.default'))
    end

    def self.config
      @config ||= YAML.load_file(File.join(IceCube::I18n::LOCALES_PATH, 'en.yml'))['en']
    end
  end
end
