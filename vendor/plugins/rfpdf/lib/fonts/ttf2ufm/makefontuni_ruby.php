<?php
/*******************************************************************************
* Utility to generate font definition files for Unicode Truetype fonts         *
* Version: 1.12                                                                *
* Date:    2003-12-30                                                          *
*******************************************************************************/

function ReadUFM($file, &$cidtogidmap)
{
  //Prepare empty CIDToGIDMap
  $cidtogidmap = str_pad('', 256*256*2, "\x00");
  
  //Read a font metric file
  $a=file($file);
  if(empty($a))
    die('File not found');
  $widths=array();
  $fm=array();
  foreach($a as $l)
  {
    $e=explode(' ',chop($l));
    if(count($e)<2)
      continue;
    $code=$e[0];
    $param=$e[1];
    if($code=='U')
    {
      // U 827 ; WX 0 ; N squaresubnosp ; G 675 ;
      //Character metrics
      $cc=(int)$e[1];
      if ($cc != -1) {
        $gn = $e[7];
        $w = $e[4];
        $glyph = $e[10];
        $widths[$cc] = $w;
        if($cc == ord('X'))
          $fm['CapXHeight'] = $e[13];
          
        // Set GID
        if ($cc >= 0 && $cc < 0xFFFF && $glyph) {
          $cidtogidmap{$cc*2} = chr($glyph >> 8);
          $cidtogidmap{$cc*2 + 1} = chr($glyph & 0xFF);
        }        
      }
      if($gn=='.notdef' && !isset($fm['MissingWidth']))
        $fm['MissingWidth']=$w;
    }
    elseif($code=='FontName')
      $fm['FontName']=$param;
    elseif($code=='Weight')
      $fm['Weight']=$param;
    elseif($code=='ItalicAngle')
      $fm['ItalicAngle']=(double)$param;
    elseif($code=='Ascender')
      $fm['Ascender']=(int)$param;
    elseif($code=='Descender')
      $fm['Descender']=(int)$param;
    elseif($code=='UnderlineThickness')
      $fm['UnderlineThickness']=(int)$param;
    elseif($code=='UnderlinePosition')
      $fm['UnderlinePosition']=(int)$param;
    elseif($code=='IsFixedPitch')
      $fm['IsFixedPitch']=($param=='true');
    elseif($code=='FontBBox')
      $fm['FontBBox']=array($e[1],$e[2],$e[3],$e[4]);
    elseif($code=='CapHeight')
      $fm['CapHeight']=(int)$param;
    elseif($code=='StdVW')
      $fm['StdVW']=(int)$param;
  }
  if(!isset($fm['MissingWidth']))
    $fm['MissingWidth']=600;

  if(!isset($fm['FontName']))
    die('FontName not found');

  $fm['Widths']=$widths;
  
  return $fm;
}

function MakeFontDescriptor($fm)
{
  //Ascent
  $asc=(isset($fm['Ascender']) ? $fm['Ascender'] : 1000);
  $fd="{'Ascent'=>".$asc;
  //Descent
  $desc=(isset($fm['Descender']) ? $fm['Descender'] : -200);
  $fd.=",'Descent'=>".$desc;
  //CapHeight
  if(isset($fm['CapHeight']))
    $ch=$fm['CapHeight'];
  elseif(isset($fm['CapXHeight']))
    $ch=$fm['CapXHeight'];
  else
    $ch=$asc;
  $fd.=",'CapHeight'=>".$ch;
  //Flags
  $flags=0;
  if(isset($fm['IsFixedPitch']) and $fm['IsFixedPitch'])
    $flags+=1<<0;
  $flags+=1<<5;
  if(isset($fm['ItalicAngle']) and $fm['ItalicAngle']!=0)
    $flags+=1<<6;
  $fd.=",'Flags'=>".$flags;
  //FontBBox
  if(isset($fm['FontBBox']))
    $fbb=$fm['FontBBox'];
  else
    $fbb=array(0,$des-100,1000,$asc+100);
  $fd.=",'FontBBox'=>'[".$fbb[0].' '.$fbb[1].' '.$fbb[2].' '.$fbb[3]."]'";
  //ItalicAngle
  $ia=(isset($fm['ItalicAngle']) ? $fm['ItalicAngle'] : 0);
  $fd.=",'ItalicAngle'=>".$ia;
  //StemV
  if(isset($fm['StdVW']))
    $stemv=$fm['StdVW'];
  elseif(isset($fm['Weight']) and eregi('(bold|black)',$fm['Weight']))
    $stemv=120;
  else
    $stemv=70;
  $fd.=",'StemV'=>".$stemv;
  //MissingWidth
  if(isset($fm['MissingWidth']))
    $fd.=",'MissingWidth'=>".$fm['MissingWidth'];
  $fd.='}';
  return $fd;
}

function MakeWidthArray($fm)
{
  //Make character width array
  $s="{";
  $cw=$fm['Widths'];
  $els=array();
  $c=0;
  foreach ($cw as $i => $w)
  {
    $els[] = ((($c++)%16==0)?"\n\t":'').$i.'=>'.$w;
  }
  $s .= implode(', ', $els);
  $s.='}';
  return $s;
}

function SaveToFile($file,$s,$mode='t')
{
  $f=fopen($file,'w'.$mode);
  if(!$f)
    die('Can\'t write to file '.$file);
  fwrite($f,$s,strlen($s));
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
  //Check if font license allows embedding
  $f=fopen($file,'rb');
  if(!$f)
    die('<B>Error:</B> Can\'t open '.$file);
  //Extract number of tables
  fseek($f,4,SEEK_CUR);
  $nb=ReadShort($f);
  fseek($f,6,SEEK_CUR);
  //Seek OS/2 table
  $found=false;
  for($i=0;$i<$nb;$i++)
  {
    if(fread($f,4)=='OS/2')
    {
      $found=true;
      break;
    }
    fseek($f,12,SEEK_CUR);
  }
  if(!$found)
  {
    fclose($f);
    return;
  }
  fseek($f,4,SEEK_CUR);
  $offset=ReadLong($f);
  fseek($f,$offset,SEEK_SET);
  //Extract fsType flags
  fseek($f,8,SEEK_CUR);
  $fsType=ReadShort($f);
  $rl=($fsType & 0x02)!=0;
  $pp=($fsType & 0x04)!=0;
  $e=($fsType & 0x08)!=0;
  fclose($f);
  if($rl and !$pp and !$e)
    echo '<B>Warning:</B> font license does not allow embedding';
}

/*******************************************************************************
* $fontfile: path to TTF file (or empty string if not to be embedded)          *
* $ufmfile:  path to UFM file                                                  *
*******************************************************************************/
function MakeFont($fontfile,$ufmfile)
{
  //Generate a font definition file
  set_magic_quotes_runtime(0);
  if(!file_exists($ufmfile))
    die('<B>Error:</B> UFM file not found: '.$ufmfile);
  $cidtogidmap = '';
  $fm=ReadUFM($ufmfile, $cidtogidmap);
  $fd=MakeFontDescriptor($fm);
  //Find font type
  if($fontfile)
  {
    $ext=strtolower(substr($fontfile,-3));
    if($ext=='ttf')
      $type='TrueTypeUnicode';
    else
      die('<B>Error:</B> not a truetype font: '.$ext);
  }
  else
  {
    if($type!='TrueTypeUnicode')
      die('<B>Error:</B> incorrect font type: '.$type);
  }
  //Start generation
  $basename=strtolower(substr(basename($ufmfile),0,-4));
  $s='TCPDFFontDescriptor.define(\''.$basename."') do |font|\n";
  $s.="  font[:type]='".$type."'\n";
  $s.="  font[:name]='".$fm['FontName']."'\n";
  $s.="  font[:desc]=".$fd."\n";
  if(!isset($fm['UnderlinePosition']))
    $fm['UnderlinePosition']=-100;
  if(!isset($fm['UnderlineThickness']))
    $fm['UnderlineThickness']=50;
  $s.="  font[:up]=".$fm['UnderlinePosition']."\n";
  $s.="  font[:ut]=".$fm['UnderlineThickness']."\n";
  $s.="  font[:cw]=".MakeWidthArray($fm)."\n";
  $s.="  font[:enc]=''\n";
  $s.="  font[:diff]=''\n";
  if($fontfile)
  {
    //Embedded font
    if(!file_exists($fontfile))
      die('<B>Error:</B> font file not found: '.$fontfile);
    CheckTTF($fontfile);
    $f=fopen($fontfile,'rb');
    if(!$f)
      die('<B>Error:</B> Can\'t open '.$fontfile);
    $file=fread($f,filesize($fontfile));
    fclose($f);
    if(function_exists('gzcompress'))
    {
      $cmp=$basename.'.z';
      SaveToFile($cmp,gzcompress($file),'b');
      $s.='  font[:file]=\''.$cmp."'\n";
      echo 'Font file compressed ('.$cmp.')<BR>';

      $cmp=$basename.'.ctg.z';
      SaveToFile($cmp,gzcompress($cidtogidmap),'b');
      echo 'CIDToGIDMap created and compressed ('.$cmp.')<BR>';     
      $s.='  font[:ctg]=\''.$cmp."'\n";
    }
    else
    {
      $s.='$file=\''.basename($fontfile)."'\n";
      echo '<B>Notice:</B> font file could not be compressed (gzcompress not available)<BR>';
      
      $cmp=$basename.'.ctg';
      $f = fopen($cmp, 'wb');
      fwrite($f, $cidtogidmap);
      fclose($f);
      echo 'CIDToGIDMap created ('.$cmp.')<BR>';
      $s.='  font[:ctg]=\''.$cmp."'\n";
    }
    if($type=='Type1')
    {
      $s.='  font[:size1]='.$size1."\n";
      $s.='  font[:size2]='.$size2."\n";
    }
    else
      $s.='  font[:originalsize]='.filesize($fontfile)."\n";
  }
  else
  {
    //Not embedded font
    $s.='  font[:file]='."''\n";
  }
  $s.="end\n";
  SaveToFile($basename.'.rb',$s);
  echo 'Font definition file generated ('.$basename.'.rb'.')<BR>';
}

$arg = $GLOBALS['argv'];
if (count($arg) >= 3) {
  ob_start();
  array_shift($arg);
  MakeFont($arg[0], $arg[1]);
  $t = ob_get_clean();
  print preg_replace('!<BR( /)?>!i', "\n", $t);
}
else {
  print "Usage: makefontuni_ruby.php <ttf-file> <ufm-file>\n";
}
?>