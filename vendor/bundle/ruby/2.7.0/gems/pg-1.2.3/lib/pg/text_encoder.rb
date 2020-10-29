# -*- ruby -*-
# frozen_string_literal: true

require 'json'
require 'ipaddr'

module PG
	module TextEncoder
		class Date < SimpleEncoder
			def encode(value)
				value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value
			end
		end

		class TimestampWithoutTimeZone < SimpleEncoder
			def encode(value)
				value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d %H:%M:%S.%N") : value
			end
		end

		class TimestampUtc < SimpleEncoder
			def encode(value)
				value.respond_to?(:utc) ? value.utc.strftime("%Y-%m-%d %H:%M:%S.%N") : value
			end
		end

		class TimestampWithTimeZone < SimpleEncoder
			def encode(value)
				value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d %H:%M:%S.%N %:z") : value
			end
		end

		class JSON < SimpleEncoder
			def encode(value)
				::JSON.generate(value, quirks_mode: true)
			end
		end

		class Inet < SimpleEncoder
			def encode(value)
				case value
				when IPAddr
					default_prefix = (value.family == Socket::AF_INET ? 32 : 128)
					s = value.to_s
					if value.respond_to?(:prefix)
						prefix = value.prefix
					else
						range = value.to_range
						prefix  = default_prefix - Math.log(((range.end.to_i - range.begin.to_i) + 1), 2).to_i
					end
					s << "/" << prefix.to_s if prefix != default_prefix
					s
				else
					value
				end
			end
		end
	end
end # module PG
