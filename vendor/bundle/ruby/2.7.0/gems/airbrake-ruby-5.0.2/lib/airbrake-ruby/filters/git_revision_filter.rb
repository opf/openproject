module Airbrake
  module Filters
    # Attaches current git revision to `context`.
    # @api private
    # @since v2.11.0
    class GitRevisionFilter
      # @return [Integer]
      attr_reader :weight

      # @return [String]
      PREFIX = 'ref: '.freeze

      # @param [String] root_directory
      def initialize(root_directory)
        @git_path = File.join(root_directory, '.git')
        @revision = nil
        @weight = 116
      end

      # @macro call_filter
      def call(notice)
        return if notice[:context].key?(:revision)

        if @revision
          notice[:context][:revision] = @revision
          return
        end

        return unless File.exist?(@git_path)

        @revision = find_revision
        return unless @revision

        notice[:context][:revision] = @revision
      end

      private

      def find_revision
        head_path = File.join(@git_path, 'HEAD')
        return unless File.exist?(head_path)

        head = File.read(head_path)
        return head unless head.start_with?(PREFIX)

        head = head.chomp[PREFIX.size..-1]

        ref_path = File.join(@git_path, head)
        return File.read(ref_path).chomp if File.exist?(ref_path)

        find_from_packed_refs(head)
      end

      def find_from_packed_refs(head)
        packed_refs_path = File.join(@git_path, 'packed-refs')
        return head unless File.exist?(packed_refs_path)

        File.readlines(packed_refs_path).each do |line|
          next if %w[# ^].include?(line[0])
          next unless (parts = line.split(' ')).size == 2
          return parts.first if parts.last == head
        end

        nil
      end
    end
  end
end
