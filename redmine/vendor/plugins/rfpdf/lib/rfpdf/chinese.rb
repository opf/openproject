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
# This is direct port of chinese.php
#
# Chinese PDF support.
#
# Usage is as follows:
#
# require 'fpdf'
# require 'chinese'
# pdf = FPDF.new
# pdf.extend(PDF_Chinese)
#
# This allows it to be combined with other extensions, such as the bookmark
# module.

module PDF_Chinese

  Big5_widths={' '=>250,'!'=>250,'"'=>408,'#'=>668,''=>490,'%'=>875,'&'=>698,'\''=>250,
  	'('=>240,')'=>240,'*'=>417,'+'=>667,','=>250,'-'=>313,'.'=>250,'/'=>520,'0'=>500,'1'=>500,
  	'2'=>500,'3'=>500,'4'=>500,'5'=>500,'6'=>500,'7'=>500,'8'=>500,'9'=>500,':'=>250,''=>250,
  	'<'=>667,'='=>667,'>'=>667,'?'=>396,'@'=>921,'A'=>677,'B'=>615,'C'=>719,'D'=>760,'E'=>625,
  	'F'=>552,'G'=>771,'H'=>802,'I'=>354,'J'=>354,'K'=>781,'L'=>604,'M'=>927,'N'=>750,'O'=>823,
  	'P'=>563,'Q'=>823,'R'=>729,'S'=>542,'T'=>698,'U'=>771,'V'=>729,'W'=>948,'X'=>771,'Y'=>677,
  	'Z'=>635,'['=>344,'\\'=>520,']'=>344,'^'=>469,'_'=>500,'`'=>250,'a'=>469,'b'=>521,'c'=>427,
  	'd'=>521,'e'=>438,'f'=>271,'g'=>469,'h'=>531,'i'=>250,'j'=>250,'k'=>458,'l'=>240,'m'=>802,
  	'n'=>531,'o'=>500,'p'=>521,'q'=>521,'r'=>365,'s'=>333,'t'=>292,'u'=>521,'v'=>458,'w'=>677,
  	'x'=>479,'y'=>458,'z'=>427,'{'=>480,'|'=>496,'end'=>480,'~'=>667}

  GB_widths={' '=>207,'!'=>270,'"'=>342,'#'=>467,''=>462,'%'=>797,'&'=>710,'\''=>239,
  	'('=>374,')'=>374,'*'=>423,'+'=>605,','=>238,'-'=>375,'.'=>238,'/'=>334,'0'=>462,'1'=>462,
  	'2'=>462,'3'=>462,'4'=>462,'5'=>462,'6'=>462,'7'=>462,'8'=>462,'9'=>462,':'=>238,''=>238,
  	'<'=>605,'='=>605,'>'=>605,'?'=>344,'@'=>748,'A'=>684,'B'=>560,'C'=>695,'D'=>739,'E'=>563,
  	'F'=>511,'G'=>729,'H'=>793,'I'=>318,'J'=>312,'K'=>666,'L'=>526,'M'=>896,'N'=>758,'O'=>772,
  	'P'=>544,'Q'=>772,'R'=>628,'S'=>465,'T'=>607,'U'=>753,'V'=>711,'W'=>972,'X'=>647,'Y'=>620,
  	'Z'=>607,'['=>374,'\\'=>333,']'=>374,'^'=>606,'_'=>500,'`'=>239,'a'=>417,'b'=>503,'c'=>427,
  	'd'=>529,'e'=>415,'f'=>264,'g'=>444,'h'=>518,'i'=>241,'j'=>230,'k'=>495,'l'=>228,'m'=>793,
  	'n'=>527,'o'=>524,'p'=>524,'q'=>504,'r'=>338,'s'=>336,'t'=>277,'u'=>517,'v'=>450,'w'=>652,
  	'x'=>466,'y'=>452,'z'=>407,'{'=>370,'|'=>258,'end'=>370,'~'=>605}

  def AddCIDFont(family,style,name,cw,cMap,registry)
#ActionController::Base::logger.debug registry.to_a.join(":").to_s
  	fontkey=family.downcase+style.upcase
  	unless @fonts[fontkey].nil?
  		Error("Font already added: family style")
		end
  	i=@fonts.length+1
  	name=name.gsub(' ','')
    @fonts[fontkey]={'i'=>i,'type'=>'Type0','name'=>name,'up'=>-130,'ut'=>40,'cw'=>cw, 'CMap'=>cMap,'registry'=>registry}
  end

  def AddCIDFonts(family,name,cw,cMap,registry)
  	AddCIDFont(family,'',name,cw,cMap,registry)
  	AddCIDFont(family,'B',name+',Bold',cw,cMap,registry)
  	AddCIDFont(family,'I',name+',Italic',cw,cMap,registry)
  	AddCIDFont(family,'BI',name+',BoldItalic',cw,cMap,registry)
  end

  def AddBig5Font(family='Big5',name='MSungStd-Light-Acro')
  	#Add Big5 font with proportional Latin
  	cw=Big5_widths
  	cMap='ETenms-B5-H'
  	registry={'ordering'=>'CNS1','supplement'=>0}
#ActionController::Base::logger.debug registry.to_a.join(":").to_s
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def AddBig5hwFont(family='Big5-hw',name='MSungStd-Light-Acro')
  	#Add Big5 font with half-witdh Latin
    cw = {}
    32.upto(126) do |i|
  		cw[i.chr]=500
		end
  	cMap='ETen-B5-H'
  	registry={'ordering'=>'CNS1','supplement'=>0}
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def AddGBFont(family='GB',name='STSongStd-Light-Acro')
  	#Add GB font with proportional Latin
  	cw=GB_widths
  	cMap='GBKp-EUC-H'
  	registry={'ordering'=>'GB1','supplement'=>2}
  	AddCIDFonts(family,name,cw,cMap,registry)
  end

  def AddGBhwFont(family='GB-hw',name='STSongStd-Light-Acro')
  	#Add GB font with half-width Latin
    32.upto(126) do |i|
  		cw[i.chr]=500
		end
  	cMap='GBK-EUC-H'
  	registry={'ordering'=>'GB1','supplement'=>2}
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
  			l+=cw[c.chr]
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
  			if(border.index('L').nil?)
  				b2+='L'
				end
  			if(border.index('R').nil?)
  				b2+='R'
				end
  			b=border.index('T').nil? ? b2+'T' : b2
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
  		if(c=="\n")
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
  		elsif(c==' ')
  			sep=i
  			ls=l
  		end
  		l+=ascii ? cw[c.chr] : 1000
  		if(l>wmax)
  			#Automatic line break
  			if(sep==-1 or i==j)
  				if(i==j)
  					i+=ascii ? 1 : 2
					end
  				Cell(w,h,s[j,i-j],b,2,align,fill)
  			else
  				Cell(w,h,s[j,sep-j],b,2,align,fill)
  				i=(s[sep]==' ') ? sep+1 : sep
  			end
  			sep=-1
  			j=i
  			l=0
#  			nl+=1
  			if(border and nl==2)
  				b=b2
  			end
  		else
  			i+=ascii ? 1 : 2
  		end
  	end
  	#Last chunk
  	if(border and not border.index('B').nil?)
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
  		if(c=="\n")
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
  		if(!ascii or c==' ')
  			sep=i
			end
  		l+=ascii ? cw[c.chr] : 1000
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
  				i=(s[sep]==' ') ? sep+1 : sep
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
  		unless info['length2'].nil?
  			out('/Length2 '+info['length2']+' /Length3 0')
			end
  		out('>>')
  		f=fopen(file,'rb')
  		putstream(fread(f,size))
  		fclose(f)
  		out('endobj')
  	end
#
  	# set_magic_quotes_runtime(mqr)
#
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
  	out('/CIDSystemInfo <</Registry '+textstring('Adobe')+' /Ordering '+textstring(font['registry']['ordering'])+' /Supplement '+font['registry']['supplement'].to_s+'>>')
  	out('/FontDescriptor '+(@n+1).to_s+' 0 R')
  	if(font['CMap']=='ETen-B5-H')
  		w='13648 13742 500'
  	elsif(font['CMap']=='GBK-EUC-H')
  		w='814 907 500 7716 [500]'
  	else
      # ActionController::Base::logger.debug font['cw'].keys.sort.join(' ').to_s
      # ActionController::Base::logger.debug font['cw'].values.join(' ').to_s
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
