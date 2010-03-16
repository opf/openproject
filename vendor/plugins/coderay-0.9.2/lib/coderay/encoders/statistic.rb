module CodeRay
module Encoders

  # Makes a statistic for the given tokens.
  class Statistic < Encoder

    include Streamable
    register_for :stats, :statistic

    attr_reader :type_stats, :real_token_count

  protected

    TypeStats = Struct.new :count, :size

    def setup options
      @type_stats = Hash.new { |h, k| h[k] = TypeStats.new 0, 0 }
      @real_token_count = 0
    end

    def generate tokens, options
      @tokens = tokens
      super
    end

    def text_token text, kind
      @real_token_count += 1 unless kind == :space
      @type_stats[kind].count += 1
      @type_stats[kind].size += text.size
      @type_stats['TOTAL'].size += text.size
      @type_stats['TOTAL'].count += 1
    end

    # TODO Hierarchy handling
    def block_token action, kind
      @type_stats['TOTAL'].count += 1
      @type_stats['open/close'].count += 1
    end

    STATS = <<-STATS

Code Statistics

Tokens            %8d
  Non-Whitespace  %8d
Bytes Total       %8d

Token Types (%d):
  type                     count     ratio    size (average)
-------------------------------------------------------------
%s
      STATS
# space                    12007   33.81 %     1.7
    TOKEN_TYPES_ROW = <<-TKR
  %-20s  %8d  %6.2f %%   %5.1f
      TKR

    def finish options
      all = @type_stats['TOTAL']
      all_count, all_size = all.count, all.size
      @type_stats.each do |type, stat|
        stat.size /= stat.count.to_f
      end
      types_stats = @type_stats.sort_by { |k, v| [-v.count, k.to_s] }.map do |k, v|
        TOKEN_TYPES_ROW % [k, v.count, 100.0 * v.count / all_count, v.size]
      end.join
      STATS % [
        all_count, @real_token_count, all_size,
        @type_stats.delete_if { |k, v| k.is_a? String }.size,
        types_stats
      ]
    end

  end

end
end
