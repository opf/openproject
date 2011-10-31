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
# This is direct port of korean.php
#
# Korean PDF support.
#
# Usage is as follows:
#
# require 'fpdf'
# require 'chinese'
# pdf = FPDF.new
# pdf.extend(PDF_Korean)
#
# This allows it to be combined with other extensions, such as the bookmark
# module.

module PDF_Korean

UHC_widths={' ' => 333, '!' => 416, '"' => 416, '#' => 833, '$' => 625, '%' => 916, '&' => 833, '\'' => 250, 
	'(' => 500, ')' => 500, '*' => 500, '+' => 833, ',' => 291, '-' => 833, '.' => 291, '/' => 375, '0' => 625, '1' => 625, 
	'2' => 625, '3' => 625, '4' => 625, '5' => 625, '6' => 625, '7' => 625, '8' => 625, '9' => 625, ':' => 333, ';' => 333, 
	'<' => 833, '=' => 833, '>' => 916, '?' => 500, '@' => 1000, 'A' => 791, 'B' => 708, 'C' => 708, 'D' => 750, 'E' => 708, 
	'F' => 666, 'G' => 750, 'H' => 791, 'I' => 375, 'J' => 500, 'K' => 791, 'L' => 666, 'M' => 916, 'N' => 791, 'O' => 750, 
	'P' => 666, 'Q' => 750, 'R' => 708, 'S' => 666, 'T' => 791, 'U' => 791, 'V' => 750, 'W' => 1000, 'X' => 708, 'Y' => 708, 
	'Z' => 666, '[' => 500, '\\' => 375, ']' => 500, '^' => 500, '_' => 500, '`' => 333, 'a' => 541, 'b' => 583, 'c' => 541, 
	'd' => 583, 'e' => 583, 'f' => 375, 'g' => 583, 'h' => 583, 'i' => 291, 'j' => 333, 'k' => 583, 'l' => 291, 'm' => 875, 
	'n' => 583, 'o' => 583, 'p' => 583, 'q' => 583, 'r' => 458, 's' => 541, 't' => 375, 'u' => 583, 'v' => 583, 'w' => 833, 
	'x' => 625, 'y' => 625, 'z' => 500, '{' => 583, '|' => 583, '}' => 583, '~' => 750}

  def AddCIDFont(family,style,name,cw,cMap,registry)
    fontkey=family.downcase+style.upcase
    unless @fonts[fontkey].nil?
  		Error("Font already added: family style")
    end
  	i=@fonts.length+1
  	name=name.gsub(' ','')
  	@fonts[fontkey]={'i'=>i,'type'=>'Type0','name'=>name,'up'=>-130,'ut'=>40,'cw'=>cw,
  	  'CMap'=>cMap,'registry'=>registry}
  end

  def AddCIDFonts(family,name,cw,cMap,registry)
  	AddCIDFont(family,'',name,cw,cMap,registry)
  	AddCIDFont(family,'B',name+',Bold',cw,cMap,registry)
  	AddCIDFont(family,'I',name+',Italic',cw,cMap,registry)
  	AddCIDFont(family,'BI',name+',BoldItalic',cw,cMap,registry)
  end

  def AddUHCFont(family='UHC',name='HYSMyeongJoStd-Medium-Acro')
  	#Add UHC font with proportional Latin
  	cw=UHC_widths
  	cMap='KSCms-UHC-H'
  	registry={'ordering'=>'Korea1','supplement'=>1}
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def AddUHChwFont(family='UHC-hw',name='HYSMyeongJoStd-Medium-Acro')
  	#Add UHC font with half-witdh Latin
    32.upto(126) do |i|
  		cw[i.chr]=500
    end
  	cMap='KSCms-UHC-HW-H'
  	registry={'ordering'=>'Korea1','supplement'=>1}
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def GetStringWidth(s)
  	if(@CurrentFont['type']=='Type0')
  		return GetMBStringWidth(s)
  	else
  		return super(s)
    end
  end

  def GetMBStringWidth(s)
  	#Multi-byte version of GetStringWidth()
  	l=0
  	cw=@CurrentFont['cw']
  	nb=s.length
  	i=0
  	while(i<nb)
  		c=s[i]
  		if(c<128)
  			l+=cw[c.chr] if cw[c.chr]
  			i+=1
  		else
  			l+=1000
  			i+=2
  		end
  	end
  	return l*@FontSize/1000
  end

  def MultiCell(w,h,txt,border=0,align='L',fill=0)
  	if(@CurrentFont['type']=='Type0')
  		MBMultiCell(w,h,txt,border,align,fill)
  	else
  		super(w,h,txt,border,align,fill)
    end
  end

  def MBMultiCell(w,h,txt,border=0,align='L',fill=0)
  	#Multi-byte version of MultiCell()
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
  		#Check if ASCII or MB
  		ascii=(c<128)
  		if(c.chr=="\n")
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
  		if(!ascii)
  			sep=i
  			ls=l
  		elsif(c.chr==' ')
  			sep=i
  			ls=l
  		end
  		l+=(ascii ? cw[c.chr] : 1000) || 0
  		if(l>wmax)
  			#Automatic line break
  			if(sep==-1 or i==j)
  				if(i==j)
  					i+=ascii ? 1 : 2
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
  			i+=ascii ? 1 : 2
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
  		MBWrite(h,txt,link)
  	else
  		super(h,txt,link)
    end
  end

  def MBWrite(h,txt,link)
  	#Multi-byte version of Write()
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
  		#Check if ASCII or MB
  		ascii=(c<128)
  		if(c.chr=="\n")
  			#Explicit line break
  			Cell(w,h,s[j,i-j],0,2,'',0,link)
  			i+=1
  			sep=-1
  			j=i
  			l=0
  			if(nl==1)
  				@x=@lMargin
  				w=@w-@rMargin-@x
  				wmax=(w-2*@cMargin)*1000/@FontSize
  			end
  			nl+=1
  			next
  		end
  		if(!ascii or c.chr==' ')
  			sep=i
      end
  		l+=(ascii ? cw[c.chr] : 1000) || 0
  		if(l>wmax)
  			#Automatic line break
  			if(sep==-1 or i==j)
  				if(@x>@lMargin)
  					#Move to next line
  					@x=@lMargin
  					@y+=h
  					w=@w-@rMargin-@x
  					wmax=(w-2*@cMargin)*1000/@FontSize
  					i+=1
  					nl+=1
  					next
  				end
  				if(i==j)
  					i+=ascii ? 1 : 2
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
  			i+=ascii ? 1 : 2
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
  		if(not info['length2'].nil?)
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
  					if(not font['diff'].nil?)
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
  	if(font['CMap']=='KSCms-UHC-HW-H')
  		w='8094 8190 500'
  	else
  		w='1 ['
  		font['cw'].keys.sort.each {|key|
  		  w+=font['cw'][key].to_s + " "
  # ActionController::Base::logger.debug key.to_s
  # ActionController::Base::logger.debug font['cw'][key].to_s
  		}
  		w +=']'
    end
  	out('/W ['+w+']>>')
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
  	out('/StemV 50')
  	out('>>')
  	out('endobj')
  end
end
