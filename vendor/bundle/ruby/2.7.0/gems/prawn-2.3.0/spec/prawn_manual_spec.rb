# frozen_string_literal: true

require 'spec_helper'
require 'digest/sha2'

MANUAL_HASH =
  case RUBY_ENGINE
  when 'ruby'
    'b38bd8aaa7b419a2f594ee8837cd62f813141000393995b0c0456644b823a62a'\
    '2f8031b2db0fc9e7c544b3946a9b0e60570d510564e6fed3931e0717dd49188a'
  when 'jruby'
    'b38bd8aaa7b419a2f594ee8837cd62f813141000393995b0c0456644b823a62a'\
    '2f8031b2db0fc9e7c544b3946a9b0e60570d510564e6fed3931e0717dd49188a'
  end

RSpec.describe Prawn do
  describe 'manual' do
    # JRuby's zlib is a bit quirky. It sometimes produces different output to
    # libzlib (used by MRI). It's still a proper deflate stream and can be
    # decompressed just fine but for whatever reason compressin produses
    # different output.
    #
    # See: https://github.com/jruby/jruby/issues/4244
    it 'contains no unexpected changes' do
      ENV['CI'] ||= 'true'

      require File.expand_path(File.join(__dir__, %w[.. manual contents]))
      s = prawn_manual_document.render

      hash = Digest::SHA512.hexdigest(s)

      expect(hash).to eq MANUAL_HASH
    end
  end
end
