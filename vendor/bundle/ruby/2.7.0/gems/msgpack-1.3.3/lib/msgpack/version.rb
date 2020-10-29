module MessagePack
  VERSION = "1.3.3"

  # NOTE for msgpack-ruby maintainer:
  # Check these things to release new binaryes for new Ruby versions (especially for Windows):
  # * versions/supports of rake-compiler & rake-compiler-dock
  #   https://github.com/rake-compiler/rake-compiler-dock/blob/master/History.md
  # * update RUBY_CC_VERSION in Rakefile
  # * check Ruby dependency of released mswin gem details
end
