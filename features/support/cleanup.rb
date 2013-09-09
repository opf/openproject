#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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



