# frozen_string_literal: true

module Zeitwerk
  module Registry # :nodoc: all
    class << self
      # Keeps track of all loaders. Useful to broadcast messages and to prevent
      # them from being garbage collected.
      #
      # @private
      # @return [<Zeitwerk::Loader>]
      attr_reader :loaders

      # Registers loaders created with `for_gem` to make the method idempotent
      # in case of reload.
      #
      # @private
      # @return [{String => Zeitwerk::Loader}]
      attr_reader :loaders_managing_gems

      # Maps real paths to the loaders responsible for them.
      #
      # This information is used by our decorated `Kernel#require` to be able to
      # invoke callbacks and autovivify modules.
      #
      # @private
      # @return [{String => Zeitwerk::Loader}]
      attr_reader :autoloads

      # This hash table addresses an edge case in which an autoload is ignored.
      #
      # For example, let's suppose we want to autoload in a gem like this:
      #
      #   # lib/my_gem.rb
      #   loader = Zeitwerk::Loader.new
      #   loader.push_dir(__dir__)
      #   loader.setup
      #
      #   module MyGem
      #   end
      #
      # if you require "my_gem", as Bundler would do, this happens while setting
      # up autoloads:
      #
      #   1. Object.autoload?(:MyGem) returns `nil` because the autoload for
      #      the constant is issued by Zeitwerk while the same file is being
      #      required.
      #   2. The constant `MyGem` is undefined while setup runs.
      #
      # Therefore, a directory `lib/my_gem` would autovivify a module according to
      # the existing information. But that would be wrong.
      #
      # To overcome this fundamental limitation, we keep track of the constant
      # paths that are in this situation ---in the example above, "MyGem"--- and
      # take this collection into account for the autovivification logic.
      #
      # Note that you cannot generally address this by moving the setup code
      # below the constant definition, because we want libraries to be able to
      # use managed constants in the module body:
      #
      #   module MyGem
      #     include MyConcern
      #   end
      #
      # @private
      # @return [{String => (String, Zeitwerk::Loader)}]
      attr_reader :inceptions

      # Registers a loader.
      #
      # @private
      # @param loader [Zeitwerk::Loader]
      # @return [void]
      def register_loader(loader)
        loaders << loader
      end

      # This method returns always a loader, the same instance for the same root
      # file. That is how Zeitwerk::Loader.for_gem is idempotent.
      #
      # @private
      # @param root_file [String]
      # @return [Zeitwerk::Loader]
      def loader_for_gem(root_file)
        loaders_managing_gems[root_file] ||= begin
          Loader.new.tap do |loader|
            loader.tag = File.basename(root_file, ".rb")
            loader.inflector = GemInflector.new(root_file)
            loader.push_dir(File.dirname(root_file))
          end
        end
      end

      # @private
      # @param loader [Zeitwerk::Loader]
      # @param realpath [String]
      # @return [void]
      def register_autoload(loader, realpath)
        autoloads[realpath] = loader
      end

      # @private
      # @param realpath [String]
      # @return [void]
      def unregister_autoload(realpath)
        autoloads.delete(realpath)
      end

      # @private
      # @param cpath [String]
      # @param realpath [String]
      # @param loader [Zeitwerk::Loader]
      # @return [void]
      def register_inception(cpath, realpath, loader)
        inceptions[cpath] = [realpath, loader]
      end

      # @private
      # @param cpath [String]
      # @return [String, nil]
      def inception?(cpath)
        if pair = inceptions[cpath]
          pair.first
        end
      end

      # @private
      # @param path [String]
      # @return [Zeitwerk::Loader, nil]
      def loader_for(path)
        autoloads[path]
      end

      # @private
      # @param loader [Zeitwerk::Loader]
      # @return [void]
      def on_unload(loader)
        autoloads.delete_if { |_path, object| object == loader }
        inceptions.delete_if { |_cpath, (_path, object)| object == loader }
      end
    end

    @loaders               = []
    @loaders_managing_gems = {}
    @autoloads             = {}
    @inceptions            = {}
  end
end
