require 'active_support/core_ext/class/attribute_accessors'

module Redmine
  module Themes
    class Theme < Struct.new(:name)
      cattr_accessor :default_theme, instance_reader: false

      def self.from(theme)
        theme.kind_of?(Theme) ? theme : new(theme)
      end

      def self.default
        self.default_theme ||= new default_theme_name
      end

      def favicon_path
        @favicon_path ||= default? ? '/favicon.ico' : "/#{name}/favicon.ico"
      end

      def main_stylesheet_path
        name.to_s
      end

      def default?
        self === self.class.default
      end

      def <=>(other)
        name.to_s <=> other.name.to_s
      end
      include Comparable

      def self.default_theme_name
        :default
      end

      def self.forget_default_theme
        self.default_theme = nil
      end
    end
  end
end
