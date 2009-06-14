# Copyright (c) 2009 Michael Koziarski <michael@koziarski.com>
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'bigdecimal'

alias BigDecimalUnsafe BigDecimal


# This fixes CVE-2009-1904 however it removes legitimate functionality that your
# application may depend on.  You are *strongly* advised to upgrade your ruby
# rather than relying on this fix for an extended period of time.

def BigDecimal(initial, digits=0)
  if initial.size > 255 || initial =~ /e/i
    raise "Invalid big Decimal Value"
  end
  BigDecimalUnsafe(initial, digits)
end

