module Airbrake
  module Filters
    # Attaches git repository URL to `context`.
    # @api private
    # @since v2.12.0
    class GitRepositoryFilter
      # @return [Integer]
      attr_reader :weight

      # @param [String] root_directory
      def initialize(root_directory)
        @git_path = File.join(root_directory, '.git')
        @repository = nil
        @git_version = detect_git_version
        @weight = 116
      end

      # @macro call_filter
      def call(notice)
        return if notice[:context].key?(:repository)

        attach_repository(notice)
      end

      def attach_repository(notice)
        if @repository
          notice[:context][:repository] = @repository
          return
        end

        return unless File.exist?(@git_path)
        return unless @git_version

        @repository =
          if @git_version >= Gem::Version.new('2.7.0')
            `cd #{@git_path} && git config --get remote.origin.url`.chomp
          else
            "`git remote get-url` is unsupported in git #{@git_version}. " \
            'Consider an upgrade to 2.7+'
          end

        return unless @repository

        notice[:context][:repository] = @repository
      end

      private

      def detect_git_version
        return unless which('git')

        Gem::Version.new(`git --version`.split[2])
      end

      # Cross-platform way to tell if an executable is accessible.
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).find do |path|
          exts.find do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            File.executable?(exe) && !File.directory?(exe)
          end
        end
      end
    end
  end
end
