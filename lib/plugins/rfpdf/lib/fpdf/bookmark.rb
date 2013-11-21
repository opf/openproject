#-- encoding: UTF-8
# Translation of the bookmark class from the PHP FPDF script from Olivier Plathey
# Translated by Sylvain Lafleur and ?? with the help of Brian Ollenberger
#
# First added in 1.53b
#
# Usage is as follows:
#
# require 'fpdf'
# require 'bookmark'
# pdf = FPDF.new
# pdf.extend(PDF_Bookmark)
#
# This allows it to be combined with other extensions, such as the Chinese
# module.

module PDF_Bookmark
    def PDF_Bookmark.extend_object(o)
        o.instance_eval('@outlines,@OutlineRoot=[],0')
        super(o)
    end

    def Bookmark(txt,level=0,y=0)
        y=self.GetY() if y==-1
        @outlines.push({'t'=>txt,'l'=>level,'y'=>y,'p'=>self.PageNo()})
    end

    def putbookmarks
        @nb=@outlines.size
        return if @nb==0
        lru=[]
        level=0
        @outlines.each_index do |i|
            o=@outlines[i]
            if o['l']>0
                parent=lru[o['l']-1]
                # Set parent and last pointers
                @outlines[i]['parent']=parent
                @outlines[parent]['last']=i
                if o['l']>level
                    # Level increasing: set first pointer
                    @outlines[parent]['first']=i
                end
            else
                @outlines[i]['parent']=@nb
            end
            if o['l']<=level and i>0
                # Set prev and next pointers
                prev=lru[o['l']]
                @outlines[prev]['next']=i
                @outlines[i]['prev']=prev
            end
            lru[o['l']]=i
            level=o['l']
        end
        # Outline items
        n=@n+1
        @outlines.each_index do |i|
            o=@outlines[i]
            newobj
            out('<</Title '+(textstring(o['t'])))
            out('/Parent '+(n+o['parent']).to_s+' 0 R')
            if o['prev']
                out('/Prev '+(n+o['prev']).to_s+' 0 R')
            end
            if o['next']
                out('/Next '+(n+o['next']).to_s+' 0 R')
            end
            if o['first']
                out('/First '+(n+o['first']).to_s+' 0 R')
            end
            if o['last']
                out('/Last '+(n+o['last']).to_s+' 0 R')
            end
            out(sprintf('/Dest [%d 0 R /XYZ 0 %.2f
null]',1+2*o['p'],(@h-o['y'])*@k))
            out('/Count 0>>')
            out('endobj')
        end
        # Outline root
        newobj
        @OutlineRoot=@n
        out('<</Type /Outlines /First '+n.to_s+' 0 R')
           out('/Last '+(n+lru[0]).to_s+' 0 R>>')
           out('endobj')
    end

    def putresources
        super
        putbookmarks
    end

    def putcatalog
        super
        if not @outlines.empty?
            out('/Outlines '+@OutlineRoot.to_s+' 0 R')
            out('/PageMode /UseOutlines')
        end
    end
end
