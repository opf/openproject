#-- encoding: UTF-8
# Information
#
# PDF_EPS class from Valentin Schmidt ported to ruby by Thiago Jackiw (tjackiw@gmail.com)
# working for Mingle LLC (www.mingle.com)
# Release Date: July 13th, 2006
#
# Description
#
# This script allows to embed vector-based Adobe Illustrator (AI) or AI-compatible EPS files.
# Only vector drawing is supported, not text or bitmap. Although the script was successfully
# tested with various AI format versions, best results are probably achieved with files that
# were exported in the AI3 format (tested with Illustrator CS2, Freehand MX and Photoshop CS2).
#
# ImageEps(string file, float x, float y [, float w [, float h [, string link [, boolean useBoundingBox]]]])
#
# Same parameters as for regular FPDF::Image() method, with an additional one:
#
# useBoundingBox: specifies whether to position the bounding box (true) or the complete canvas (false)
# at location (x,y). Default value is true.
#
# First added to the Ruby FPDF distribution in 1.53c
#
# Usage is as follows:
#
# require 'fpdf'
# require 'fpdf_eps'
# pdf = FPDF.new
# pdf.extend(PDF_EPS)
# pdf.ImageEps(...)
#
# This allows it to be combined with other extensions, such as the bookmark
# module.

module PDF_EPS
    def ImageEps(file, x, y, w=0, h=0, link='', use_bounding_box=true)
        data = nil
        if File.exists?(file)
            File.open(file, 'rb') do |f|
                data = f.read()
            end
        else
            Error('EPS file not found: '+file)
        end

        # Find BoundingBox param
        regs = data.scan(/%%BoundingBox: [^\r\n]*/m)
        regs << regs[0].gsub(/%%BoundingBox: /, '')
        if regs.size > 1
            tmp = regs[1].to_s.split(' ')
            @x1 = tmp[0].to_i
            @y1 = tmp[1].to_i
            @x2 = tmp[2].to_i
            @y2 = tmp[3].to_i
        else
            Error('No BoundingBox found in EPS file: '+file)
        end
        f_start = data.index('%%EndSetup')
        f_start = data.index('%%EndProlog') if f_start === false
        f_start = data.index('%%BoundingBox') if f_start === false

        data = data.slice(f_start, data.length)

        f_end = data.index('%%PageTrailer')
        f_end = data.index('showpage') if f_end === false
        data = data.slice(0, f_end) if f_end

        # save the current graphic state
        out('q')

        k = @k

        # Translate
        if use_bounding_box
            dx = x*k-@x1
            dy = @hPt-@y2-y*k
        else
            dx = x*k
            dy = -y*k
        end
        tm = [1,0,0,1,dx,dy]
        out(sprintf('%.3f %.3f %.3f %.3f %.3f %.3f cm',
            tm[0], tm[1], tm[2], tm[3], tm[4], tm[5]))

        if w > 0
            scale_x = w/((@x2-@x1)/k)
            if h > 0
                scale_y = h/((@y2-@y1)/k)
            else
                scale_y = scale_x
                h = (@y2-@y1)/k * scale_y
            end
        else
            if h > 0
                scale_y = $h/((@y2-@y1)/$k)
                scale_x = scale_y
                w = (@x2-@x1)/k * scale_x
            else
                w = (@x2-@x1)/k
                h = (@y2-@y1)/k
            end
        end

        if !scale_x.nil?
            # Scale
            tm = [scale_x,0,0,scale_y,0,@hPt*(1-scale_y)]
            out(sprintf('%.3f %.3f %.3f %.3f %.3f %.3f cm',
                tm[0], tm[1], tm[2], tm[3], tm[4], tm[5]))
        end

        data.split(/\r\n|[\r\n]/).each do |line|
            next if line == '' || line[0,1] == '%'
            len = line.length
            # next if (len > 2 && line[len-2,len] != ' ')
            cmd = line[len-2,len].strip
            case cmd
                when 'm', 'l', 'v', 'y', 'c', 'k', 'K', 'g', 'G', 's', 'S', 'J', 'j', 'w', 'M', 'd':
                    out(line)

                when 'L':
                    line[len-1,len]='l'
                    out(line)

                when 'C':
                    line[len-1,len]='c'
                    out(line)

                when 'f', 'F':
                    out('f*')

                when 'b', 'B':
                    out(cmd + '*')
            end
        end

        # restore previous graphic state
        out('Q')
        Link(x,y,w,h,link) if link
    end
end
