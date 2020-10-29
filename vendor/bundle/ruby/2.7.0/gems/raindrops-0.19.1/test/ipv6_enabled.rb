def ipv6_enabled?
  tmp = TCPServer.new(ENV["TEST_HOST6"] || '::1', 0)
  tmp.close
  true
rescue => e
  warn "skipping IPv6 tests, host does not seem to be IPv6 enabled:"
  warn "  #{e.class}: #{e}"
  false
end
