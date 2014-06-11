#-- encoding: UTF-8
# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This implements native php methods used by tcpdf, which have had to be
# reimplemented within Ruby.

module RFPDF

  # http://uk2.php.net/getimagesize
  def getimagesize(filename)
    out = Hash.new
    out[2] = ImageScience.image_type(filename)

    image = ImageScience.with_image(filename) do |img|
      out[0] = image.width
      out[1] = image.height

      # These are actually meant to return integer values But I couldn't seem to find anything saying what those values are.
      # So for now they return strings. The only place that uses this at the moment is the parsejpeg method, so I've changed that too.
      case out[2]
      when "GIF"
        out['mime'] = "image/gif"
      when "JPEG"
        out['mime'] = "image/jpeg"
      when "PNG"
        out['mime'] = "image/png"
      when "WBMP"
        out['mime'] = "image/vnd.wap.wbmp"
      when "XPM"
        out['mime'] = "image/x-xpixmap"
      end
      out[3] = "height=\"#{image.height}\" width=\"#{image.width}\""

      if image.colorspace == "CMYK" || image.colorspace == "RGBA"
          out['channels'] = 4
      elsif image.colorspace == "RGB"
        out['channels'] = 3
      end

      out['bits'] = image.depth
      out['bits'] /= out['channels'] if out['channels']
    end

    out
  end

end
