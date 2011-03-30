
#*****************************************************************************
# Utility to generate font definition files                                   #
# Version: 1.13                                                               #
# Date:    2004-12-31                                                         #
******************************************************************************#

function ReadMap($enc)
{
	#Read a map file
	$file=dirname(__FILE__) + '/' + $enc.downcase + '.map';
	$a=file($file);
	if ($a))
		die('<B>Error:</B> encoding not found: '.$enc);
	$cc2gn = []
	foreach($a as $l)
	{
		if ($l{0}=='!')
		{
			$e=rtrim($l).scan('/[ \\t]+/');
			$cc=hexdec(substr($e[0],1));
			$gn=$e[2];
			$cc2gn[$cc]=$gn;
		end
	end
	for($i=0;$i<=255;$i++)
	{
		if (!$cc2gn[$i].nil?)
			$cc2gn[$i]='.notdef';
	end
	return $cc2gn;
}

function ReadAFM($file,&$map)
{
	#Read a font metric file
	$a=file($file);
	if ($a.empty?)
		die('File not found');
	$widths = []
	$fm = []
	$fix=Hash.new('Edot'=>'Edotaccent','edot'=>'edotaccent','Idot'=>'Idotaccent','Zdot'=>'Zdotaccent','zdot'=>'zdotaccent',
		'Odblacute'=>'Ohungarumlaut','odblacute'=>'ohungarumlaut','Udblacute'=>'Uhungarumlaut','udblacute'=>'uhungarumlaut',
		'Gcedilla'=>'Gcommaaccent','gcedilla'=>'gcommaaccent','Kcedilla'=>'Kcommaaccent','kcedilla'=>'kcommaaccent',
		'Lcedilla'=>'Lcommaaccent','lcedilla'=>'lcommaaccent','Ncedilla'=>'Ncommaaccent','ncedilla'=>'ncommaaccent',
		'Rcedilla'=>'Rcommaaccent','rcedilla'=>'rcommaaccent','Scedilla'=>'Scommaaccent','scedilla'=>'scommaaccent',
		'Tcedilla'=>'Tcommaaccent','tcedilla'=>'tcommaaccent','Dslash'=>'Dcroat','dslash'=>'dcroat','Dmacron'=>'Dcroat','dmacron'=>'dcroat',
		'combininggraveaccent'=>'gravecomb','combininghookabove'=>'hookabovecomb','combiningtildeaccent'=>'tildecomb',
		'combiningacuteaccent'=>'acutecomb','combiningdotbelow'=>'dotbelowcomb','dongsign'=>'dong');
	foreach($a as $l)
	{
		$e=explode(' ',rtrim($l));
		if ($e.length<2)
			continue;
		$code=$e[0];
		$param=$e[1];
		if ($code=='C')
		{
			#Character metrics
			$cc=(int)$e[1];
			$w=$e[4];
			$gn=$e[7];
			if (substr($gn,-4)=='20AC')
				$gn='Euro';
			if ($fix[$gn].nil?)
			{
				#Fix incorrect glyph name
				foreach($map as $c=>$n)
				{
					if ($n==$fix[$gn])
						$map[$c]=$gn;
				end
			end
			if ($map.empty?)
			{
				#Symbolic font: use built-in encoding
				$widths[$cc]=$w;
			else
			{
				$widths[$gn]=$w;
				if ($gn=='X')
					$fm['CapXHeight']=$e[13];
			end
			if ($gn=='.notdef')
				$fm['MissingWidth']=$w;
		elsif ($code=='FontName')
			$fm['FontName']=$param;
		elsif ($code=='Weight')
			$fm['Weight']=$param;
		elsif ($code=='ItalicAngle')
			$fm['ItalicAngle']=(double)$param;
		elsif ($code=='Ascender')
			$fm['Ascender']=(int)$param;
		elsif ($code=='Descender')
			$fm['Descender']=(int)$param;
		elsif ($code=='UnderlineThickness')
			$fm['UnderlineThickness']=(int)$param;
		elsif ($code=='UnderlinePosition')
			$fm['UnderlinePosition']=(int)$param;
		elsif ($code=='IsFixedPitch')
			$fm['IsFixedPitch']=($param=='true');
		elsif ($code=='FontBBox')
			$fm['FontBBox']=Hash.new($e[1],$e[2],$e[3],$e[4]);
		elsif ($code=='CapHeight')
			$fm['CapHeight']=(int)$param;
		elsif ($code=='StdVW')
			$fm['StdVW']=(int)$param;
	end
	if (!$fm['FontName'].nil?)
		die('FontName not found');
	if (!$map.empty?)
	{
		if (!$widths['.notdef'].nil?)
			$widths['.notdef']=600;
		if (!$widths['Delta'].nil? and $widths['increment'].nil?)
			$widths['Delta']=$widths['increment'];
		#Order widths according to map
		for($i=0;$i<=255;$i++)
		{
			if (!$widths[$map[$i]].nil?)
			{
				echo '<B>Warning:</B> character '.$map[$i].' is missing<BR>';
				$widths[$i]=$widths['.notdef'];
			else
				$widths[$i]=$widths[$map[$i]];
		end
	end
	$fm['Widths']=$widths;
	return $fm;
}

function MakeFontDescriptor($fm,$symbolic)
{
	#Ascent
	$asc=($fm['Ascender'].nil? ? $fm['Ascender'] : 1000);
	$fd="Hash.new('Ascent'=>".$asc;
	#Descent
	$desc=($fm['Descender'].nil? ? $fm['Descender'] : -200);
	$fd<<",'Descent'=>".$desc;
	#CapHeight
	if ($fm['CapHeight'].nil?)
		$ch=$fm['CapHeight'];
	elsif ($fm['CapXHeight'].nil?)
		$ch=$fm['CapXHeight'];
	else
		$ch=$asc;
	$fd<<",'CapHeight'=>".$ch;
	#Flags
	$flags=0;
	if ($fm['IsFixedPitch'].nil? and $fm['IsFixedPitch'])
		$flags+=1<<0;
	if ($symbolic)
		$flags+=1<<2;
	if (!$symbolic)
		$flags+=1<<5;
	if ($fm['ItalicAngle'].nil? and $fm['ItalicAngle']!=0)
		$flags+=1<<6;
	$fd<<",'Flags'=>".$flags;
	#FontBBox
	if ($fm['FontBBox'].nil?)
		$fbb=$fm['FontBBox'];
	else
		$fbb=Hash.new(0,$des-100,1000,$asc+100);
	$fd<<",'FontBBox'=>'[".$fbb[0].' '.$fbb[1].' '.$fbb[2].' '.$fbb[3]."]'";
	#ItalicAngle
	$ia=($fm['ItalicAngle'].nil? ? $fm['ItalicAngle'] : 0);
	$fd<<",'ItalicAngle'=>".$ia;
	#StemV
	if ($fm['StdVW'].nil?)
		$stemv=$fm['StdVW'];
	elsif ($fm['Weight'].nil? and eregi('(bold|black)',$fm['Weight']))
		$stemv=120;
	else
		$stemv=70;
	$fd<<",'StemV'=>".$stemv;
	#MissingWidth
	if ($fm['MissingWidth'].nil?)
		$fd<<",'MissingWidth'=>".$fm['MissingWidth'];
	$fd<<')';
	return $fd;
}

function MakeWidthArray($fm)
{
	#Make character width array
	$s="Hash.new(\n\t";
	$cw=$fm['Widths'];
	for($i=0;$i<=255;$i++)
	{
		if ($i.chr=="'")
			$s<<"'\\''";
		elsif ($i.chr=="\\")
			$s<<"'\\\\'";
		elsif ($i>=32 and $i<=126)
			$s<<"'".$i.chr."'";
		else
			$s<<"$i.chr";
		$s<<'=>'.$fm['Widths'][$i];
		if ($i<255)
			$s<<',';
		if (($i+1)%22==0)
			$s<<"\n\t";
	end
	$s<<')';
	return $s;
}

function MakeFontEncoding($map)
{
	#Build differences from reference encoding
	$ref=ReadMap('cp1252');
	$s='';
	$last=0;
	for($i=32;$i<=255;$i++)
	{
		if ($map[$i]!=$ref[$i])
		{
			if ($i!=$last+1)
				$s<<$i.' ';
			$last=$i;
			$s<<'/'.$map[$i].' ';
		end
	end
	return rtrim($s);
}

function SaveToFile($file,$s,$mode='t')
{
	$f=fopen($file,'w'.$mode);
	if (!$f)
		die('Can\'t write to file '.$file);
	fwrite($f,$s,$s.length);
	fclose($f);
}

function ReadShort($f)
{
	$a=unpack('n1n',fread($f,2));
	return $a['n'];
}

function ReadLong($f)
{
	$a=unpack('N1N',fread($f,4));
	return $a['N'];
}

function CheckTTF($file)
{
	#Check if font license allows embedding
	$f=fopen($file,'rb');
	if (!$f)
		die('<B>Error:</B> Can\'t open '.$file);
	#Extract number of tables
	fseek($f,4,SEEK_CUR);
	$nb=ReadShort($f);
	fseek($f,6,SEEK_CUR);
	#Seek OS/2 table
	$found=false;
	for($i=0;$i<$nb;$i++)
	{
		if (fread($f,4)=='OS/2')
		{
			$found=true;
			break;
		end
		fseek($f,12,SEEK_CUR);
	end
	if (!$found)
	{
		fclose($f);
		return;
	end
	fseek($f,4,SEEK_CUR);
	$offset=ReadLong($f);
	fseek($f,$offset,SEEK_SET);
	#Extract fsType flags
	fseek($f,8,SEEK_CUR);
	$fsType=ReadShort($f);
	$rl=($fsType & 0x02)!=0;
	$pp=($fsType & 0x04)!=0;
	$e=($fsType & 0x08)!=0;
	fclose($f);
	if ($rl and !$pp and !$e)
		echo '<B>Warning:</B> font license does not allow embedding';
}

#*****************************************************************************
# $fontfile : chemin du fichier TTF (ou chaîne vide si pas d'incorporation)   #
# $afmfile :  chemin du fichier AFM                                           #
# $enc :      encodage (ou chaîne vide si la police est symbolique)           #
# $patch :    patch optionnel pour l'encodage                                 #
# $type :     type de la police si $fontfile est vide                         #
******************************************************************************#
function MakeFont($fontfile,$afmfile,$enc='cp1252',$patch=Hash.new(),$type='TrueType')
{
	#Generate a font definition file
	set_magic_quotes_runtime(0);
	ini_set('auto_detect_line_endings','1');
	if ($enc)
	{
		$map=ReadMap($enc);
		foreach($patch as $cc=>$gn)
			$map[$cc]=$gn;
	end
	else
		$map = []
	if (!file_exists($afmfile))
		die('<B>Error:</B> AFM file not found: '.$afmfile);
	$fm=ReadAFM($afmfile,$map);
	if ($enc)
		$diff=MakeFontEncoding($map);
	else
		$diff='';
	$fd=MakeFontDescriptor($fm,$map.empty?);
	#Find font type
	if ($fontfile)
	{
		$ext=strtolower(substr($fontfile,-3));
		if ($ext=='ttf')
			$type='TrueType';
		elsif ($ext=='pfb')
			$type='Type1';
		else
			die('<B>Error:</B> unrecognized font file extension: '.$ext);
	end
	else
	{
		if ($type!='TrueType' and $type!='Type1')
			die('<B>Error:</B> incorrect font type: '.$type);
	end
	#Start generation
	$s=''."\n";
	$s<<'$type=\''.$type."';\n";
	$s<<'$name=\''.$fm['FontName']."';\n";
	$s<<'$desc='.$fd.";\n";
	if (!$fm['UnderlinePosition'].nil?)
		$fm['UnderlinePosition']=-100;
	if (!$fm['UnderlineThickness'].nil?)
		$fm['UnderlineThickness']=50;
	$s<<'$up='.$fm['UnderlinePosition'].";\n";
	$s<<'$ut='.$fm['UnderlineThickness'].";\n";
	$w=MakeWidthArray($fm);
	$s<<'$cw='.$w.";\n";
	$s<<'$enc=\''.$enc."';\n";
	$s<<'$diff=\''.$diff."';\n";
	$basename=substr(basename($afmfile),0,-4);
	if ($fontfile)
	{
		#Embedded font
		if (!file_exists($fontfile))
			die('<B>Error:</B> font file not found: '.$fontfile);
		if ($type=='TrueType')
			CheckTTF($fontfile);
		$f=fopen($fontfile,'rb');
		if (!$f)
			die('<B>Error:</B> Can\'t open '.$fontfile);
		$file=fread($f,filesize($fontfile));
		fclose($f);
		if ($type=='Type1')
		{
			#Find first two sections and discard third one
			$header=($file[0][0]==128);
			if ($header)
			{
				#Strip first binary header
				$file=substr($file,6);
			end
			$pos=$file.include?('eexec');
			if (!$pos)
				die('<B>Error:</B> font file does not seem to be valid Type1');
			$size1=$pos+6;
			if ($header and ?($file{$size1})==128)
			{
				#Strip second binary header
				$file=substr($file,0,$size1).substr($file,$size1+6);
			end
			$pos=$file.include?('00000000');
			if (!$pos)
				die('<B>Error:</B> font file does not seem to be valid Type1');
			$size2=$pos-$size1;
			$file=substr($file,0,$size1+$size2);
		end
		if (respond_to('gzcompress'))
		{
			$cmp=$basename.'.z';
			SaveToFile($cmp,gzcompress($file),'b');
			$s<<'$file=\''.$cmp."';\n";
			echo 'Font file compressed ('.$cmp.')<BR>';
		else
		{
			$s<<'$file=\''.basename($fontfile)."';\n";
			echo '<B>Notice:</B> font file could not be compressed (zlib extension not available)<BR>';
		end
		if ($type=='Type1')
		{
			$s<<'$size1='.$size1.";\n";
			$s<<'$size2='.$size2.";\n";
		else
			$s<<'$originalsize='.filesize($fontfile).";\n";
	end
	else
	{
		#Not embedded font
		$s<<'$file='."'';\n";
	end
	$s<<"\n";
	SaveToFile($basename.'.rb',$s);
	echo 'Font definition file generated ('.$basename.'.rb'.')<BR>';
}

