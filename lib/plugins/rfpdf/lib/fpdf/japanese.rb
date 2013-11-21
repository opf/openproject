#-- encoding: UTF-8
# Copyright (c) 2006 4ssoM LLC <www.4ssoM.com>
# 1.12 contributed by Ed Moss.
#
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
# This is direct port of japanese.php
#
# Japanese PDF support.
#
# Usage is as follows:
#
# require 'fpdf'
# require 'chinese'
# pdf = FPDF.new
# pdf.extend(PDF_Japanese)
#
# This allows it to be combined with other extensions, such as the bookmark
# module.

module PDF_Japanese

  SJIS_widths={' ' => 278, '!' => 299, '"' => 353, '#' => 614, '$' => 614, '%' => 721, '&' => 735, '\'' => 216, 
  	'(' => 323, ')' => 323, '*' => 449, '+' => 529, ',' => 219, '-' => 306, '.' => 219, '/' => 453, '0' => 614, '1' => 614, 
  	'2' => 614, '3' => 614, '4' => 614, '5' => 614, '6' => 614, '7' => 614, '8' => 614, '9' => 614, ':' => 219, ';' => 219, 
  	'<' => 529, '=' => 529, '>' => 529, '?' => 486, '@' => 744, 'A' => 646, 'B' => 604, 'C' => 617, 'D' => 681, 'E' => 567, 
  	'F' => 537, 'G' => 647, 'H' => 738, 'I' => 320, 'J' => 433, 'K' => 637, 'L' => 566, 'M' => 904, 'N' => 710, 'O' => 716, 
  	'P' => 605, 'Q' => 716, 'R' => 623, 'S' => 517, 'T' => 601, 'U' => 690, 'V' => 668, 'W' => 990, 'X' => 681, 'Y' => 634, 
  	'Z' => 578, '[' => 316, '\\' => 614, ']' => 316, '^' => 529, '_' => 500, '`' => 387, 'a' => 509, 'b' => 566, 'c' => 478, 
  	'd' => 565, 'e' => 503, 'f' => 337, 'g' => 549, 'h' => 580, 'i' => 275, 'j' => 266, 'k' => 544, 'l' => 276, 'm' => 854, 
  	'n' => 579, 'o' => 550, 'p' => 578, 'q' => 566, 'r' => 410, 's' => 444, 't' => 340, 'u' => 575, 'v' => 512, 'w' => 760, 
  	'x' => 503, 'y' => 529, 'z' => 453, '{' => 326, '|' => 380, '}' => 326, '~' => 387}

  def AddCIDFont(family,style,name,cw,cMap,registry)  	
    fontkey=family.downcase+style.upcase
  	unless @fonts[fontkey].nil?
  		Error("CID font already added: family style")
  	end  
  	i=@fonts.length+1
  	@fonts[fontkey]={'i'=>i,'type'=>'Type0','name'=>name,'up'=>-120,'ut'=>40,'cw'=>cw,
  	  'CMap'=>cMap,'registry'=>registry}
  end

  def AddCIDFonts(family,name,cw,cMap,registry)
  	AddCIDFont(family,'',name,cw,cMap,registry)
  	AddCIDFont(family,'B',name+',Bold',cw,cMap,registry)
  	AddCIDFont(family,'I',name+',Italic',cw,cMap,registry)
  	AddCIDFont(family,'BI',name+',BoldItalic',cw,cMap,registry)
  end

  def AddSJISFont(family='SJIS')
  	#Add SJIS font with proportional Latin
  	name='KozMinPro-Regular-Acro'
  	cw=SJIS_widths
  	cMap='90msp-RKSJ-H'
  	registry={'ordering'=>'Japan1','supplement'=>2}
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def AddSJIShwFont(family='SJIS-hw')
  	#Add SJIS font with half-width Latin
  	name='KozMinPro-Regular-Acro'
    32.upto(126) do |i|
  		cw[i.chr]=500
  	end  
  	cMap='90ms-RKSJ-H'
  	registry={'ordering'=>'Japan1','supplement'=>2}
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def GetStringWidth(s)
  	if(@CurrentFont['type']=='Type0')
  		return GetSJISStringWidth(s)
  	else
  		return super(s)
  	end  
  end

  def GetSJISStringWidth(s)
  	#SJIS version of GetStringWidth()
  	l=0
  	cw=@CurrentFont['cw']
  	nb=s.length
  	i=0
  	while(i<nb)
  		o=s[i]
  		if(o<128)
  			#ASCII
  			l+=cw[o.chr] if cw[o.chr]
  			i+=1
  		elsif(o>=161 and o<=223)
  			#Half-width katakana
  			l+=500
  			i+=1
  		else
  			#Full-width character
  			l+=1000
  			i+=2
  		end
  	end
  	return l*@FontSize/1000
  end

  def MultiCell(w,h,txt,border=0,align='L',fill=0)
  	if(@CurrentFont['type']=='Type0')
  		SJISMultiCell(w,h,txt,border,align,fill)
  	else
  		super(w,h,txt,border,align,fill)
  	end  
  end

  def SJISMultiCell(w,h,txt,border=0,align='L',fill=0)
  	#Output text with automatic or explicit line breaks
  	cw=@CurrentFont['cw']
  	if(w==0)
  		w=@w-@rMargin-@x
  	end  
  	wmax=(w-2*@cMargin)*1000/@FontSize
  	s=txt.gsub("\r",'')
  	nb=s.length
  	if(nb>0 and s[nb-1]=="\n")
  		nb-=1
  	end  
  	b=0
  	if(border)
  		if(border==1)
  			border='LTRB'
  			b='LRT'
  			b2='LR'
  		else
  			b2=''
  			b2='L' unless border.to_s.index('L').nil?
  			b2=b2+'R' unless border.to_s.index('R').nil?
  			b=(border.to_s.index('T')) ? (b2+'T') : b2
  		end
  	end
  	sep=-1
  	i=0
  	j=0
  	l=0
  	nl=1
  	while(i<nb)
  		#Get next character
  		c=s[i]
  		o=c #o=ord(c)
  		if(o==10)
  			#Explicit line break
  			Cell(w,h,s[j,i-j],b,2,align,fill)
  			i+=1
  			sep=-1
  			j=i
  			l=0
  			nl+=1
  			if(border and nl==2)
  				b=b2
      	end  
  			next
  		end
  		if(o<128)
  			#ASCII
  			l+=cw[c.chr] || 0
  			n=1
  			if(o==32)
  				sep=i
      	end  
  		elsif(o>=161 and o<=223)
  			#Half-width katakana
  			l+=500
  			n=1
  			sep=i
  		else
  			#Full-width character
  			l+=1000
  			n=2
  			sep=i
  		end
  		if(l>wmax)
  			#Automatic line break
  			if(sep==-1 or i==j)
  				if(i==j)
  					i+=n
        	end  
  				Cell(w,h,s[j,i-j],b,2,align,fill)
  			else
  				Cell(w,h,s[j,sep-j],b,2,align,fill)
  				i=(s[sep].chr==' ') ? sep+1 : sep
  			end
  			sep=-1
  			j=i
  			l=0
  			nl+=1
  			if(border and nl==2)
  				b=b2
      	end  
  		else
  			i+=n
  			if(o>=128)
  				sep=i
  			end
  		end
  	end
  	#Last chunk
  	if(border and not border.to_s.index('B').nil?)
  		b+='B'
  	end  
  	Cell(w,h,s[j,i-j],b,2,align,fill)
  	@x=@lMargin
  end

  def Write(h,txt,link='')
  	if(@CurrentFont['type']=='Type0')
 		SJISWrite(h,txt,link)
 	else
 		super(h,txt,link)
  	end  
  end

  def SJISWrite(h,txt,link)
  	#SJIS version of Write()
  	cw=@CurrentFont['cw']
  	w=@w-@rMargin-@x
  	wmax=(w-2*@cMargin)*1000/@FontSize
  	s=txt.gsub("\r",'')
  	nb=s.length
  	sep=-1
  	i=0
  	j=0
  	l=0
  	nl=1
  	while(i<nb)
  		#Get next character
  		c=s[i]
  		o=c
  		if(o==10)
  			#Explicit line break
  			Cell(w,h,s[j,i-j],0,2,'',0,link)
  			i+=1
  			sep=-1
  			j=i
  			l=0
  			if(nl==1)
  				#Go to left margin
  				@x=@lMargin
  				w=@w-@rMargin-@x
  				wmax=(w-2*@cMargin)*1000/@FontSize
  			end
  			nl+=1
  			next
  		end
  		if(o<128)
  			#ASCII
  			l+=cw[c.chr] || 0
  			n=1
  			if(o==32)
  				sep=i
      	end  
  		elsif(o>=161 and o<=223)
  			#Half-width katakana
  			l+=500
  			n=1
  			sep=i
  		else
  			#Full-width character
  			l+=1000
  			n=2
  			sep=i
  		end
  		if(l>wmax)
  			#Automatic line break
  			if(sep==-1 or i==j)
  				if(@x>@lMargin)
  					#Move to next line
  					@x=@lMargin
  					@y+=h
  					w=@w-@rMargin-@x
  					wmax=(w-2*@cMargin)*1000/@FontSize
  					i+=n
  					nl+=1
  					next
  				end
  				if(i==j)
  					i+=n
        	end  
  				Cell(w,h,s[j,i-j],0,2,'',0,link)
  			else
  				Cell(w,h,s[j,sep-j],0,2,'',0,link)
  				i=(s[sep].chr==' ') ? sep+1 : sep
  			end
  			sep=-1
  			j=i
  			l=0
  			if(nl==1)
  				@x=@lMargin
  				w=@w-@rMargin-@x
  				wmax=(w-2*@cMargin)*1000/@FontSize
  			end
  			nl+=1
  		else
  			i+=n
  			if(o>=128)
  				sep=i
      	end  
  		end
  	end
  	#Last chunk
  	if(i!=j)
  		Cell(l/1000*@FontSize,h,s[j,i-j],0,0,'',0,link)
  	end  
  end
  
private

  def putfonts()
  	nf=@n
    @diffs.each do |diff|
  		#Encodings
  		newobj()
  		out('<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences ['+diff+']>>')
  		out('endobj')
  	end
  	# mqr=get_magic_quotes_runtime()
  	# set_magic_quotes_runtime(0)
    @FontFiles.each_pair do |file, info|
  		#Font file embedding
  		newobj()
  		@FontFiles[file]['n']=@n
  		if(defined('FPDF_FONTPATH'))
  			file=FPDF_FONTPATH+file
    	end  
  		size=filesize(file)
  		if(!size)
  			Error('Font file not found')
    	end  
  		out('<</Length '+size)
  		if(file[-2]=='.z')
  			out('/Filter /FlateDecode')
    	end  
  		out('/Length1 '+info['length1'])
  		unless info['length2'].nil?
  			out('/Length2 '+info['length2']+' /Length3 0')
    	end  
  		out('>>')
  		f=fopen(file,'rb')
  		putstream(fread(f,size))
  		fclose(f)
  		out('endobj')
  	end
  	# set_magic_quotes_runtime(mqr)
    @fonts.each_pair do |k, font|
  		#Font objects
  		newobj()
  		@fonts[k]['n']=@n
  		out('<</Type /Font')
  		if(font['type']=='Type0')
  			putType0(font)
  		else
  			name=font['name']
  			out('/BaseFont /'+name)
  			if(font['type']=='core')
  				#Standard font
  				out('/Subtype /Type1')
  				if(name!='Symbol' and name!='ZapfDingbats')
  					out('/Encoding /WinAnsiEncoding')
  				end
  			else
  				#Additional font
  				out('/Subtype /'+font['type'])
  				out('/FirstChar 32')
  				out('/LastChar 255')
  				out('/Widths '+(@n+1)+' 0 R')
  				out('/FontDescriptor '+(@n+2)+' 0 R')
  				if(font['enc'])
  					if !font['diff'].nil?
  						out('/Encoding '+(nf+font['diff'])+' 0 R')
  					else
  						out('/Encoding /WinAnsiEncoding')
          	end  
  				end
  			end
  			out('>>')
  			out('endobj')
  			if(font['type']!='core')
  				#Widths
  				newobj()
  				cw=font['cw']
  				s='['
          32.upto(255) do |i|
  					s+=cw[i.chr]+' '
        	end  
  				out(s+']')
  				out('endobj')
  				#Descriptor
  				newobj()
  				s='<</Type /FontDescriptor /FontName /'+name
  				font['desc'].each_pair do |k, v|
  					s+=' /'+k+' '+v
        	end  
  				file=font['file']
  				if(file)
  					s+=' /FontFile'+(font['type']=='Type1' ? '' : '2')+' '+@FontFiles[file]['n']+' 0 R'
        	end  
  				out(s+'>>')
  				out('endobj')
  			end
  		end
  	end
  end

  def putType0(font)
  	#Type0
  	out('/Subtype /Type0')
  	out('/BaseFont /'+font['name']+'-'+font['CMap'])
  	out('/Encoding /'+font['CMap'])
  	out('/DescendantFonts ['+(@n+1).to_s+' 0 R]')
  	out('>>')
  	out('endobj')
  	#CIDFont
  	newobj()
  	out('<</Type /Font')
  	out('/Subtype /CIDFontType0')
  	out('/BaseFont /'+font['name'])
  	out('/CIDSystemInfo <</Registry (Adobe) /Ordering ('+font['registry']['ordering']+') /Supplement '+font['registry']['supplement'].to_s+'>>')
  	out('/FontDescriptor '+(@n+1).to_s+' 0 R')
  	w='/W [1 ['
		font['cw'].keys.sort.each {|key|
		  w+=font['cw'][key].to_s + " "
# ActionController::Base::logger.debug key.to_s
# ActionController::Base::logger.debug font['cw'][key].to_s
		}
  	out(w+'] 231 325 500 631 [500] 326 389 500]')
  	out('>>')
  	out('endobj')
  	#Font descriptor
  	newobj()
  	out('<</Type /FontDescriptor')
  	out('/FontName /'+font['name'])
  	out('/Flags 6')
  	out('/FontBBox [0 -200 1000 900]')
  	out('/ItalicAngle 0')
  	out('/Ascent 800')
  	out('/Descent -200')
  	out('/CapHeight 800')
  	out('/StemV 60')
  	out('>>')
  	out('endobj')
  end
end
