module Support
  module Cleanup
    def self.to_clean(&block)
      cleanings << block
    end

    def self.cleanup
      cleanings.each do |block|
        block.call
      end

      reset_cleanings
    end

    private

    def self.cleanings
      @cleanings ||= []
    end

    def self.reset_cleanings
      @cleanings = []
    end
  end
end

After do
  Support::Cleanup.cleanup
end



