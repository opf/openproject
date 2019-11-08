/**
 * @private
 */
var K3D = {};

K3D.load = function(path, resp)
{
    var request = new XMLHttpRequest();
    request.open("GET", path, true);
    request.responseType = "arraybuffer";
    request.onload = function(e){resp(e.target.response);};
    request.send();
}

K3D.save = function(buff, path)
{
    var dataURI = "data:application/octet-stream;base64," + btoa(K3D.parse._buffToStr(buff));
    window.location.href = dataURI;
}

K3D.clone = function(o)
{
    return JSON.parse(JSON.stringify(o));
}



K3D.bin = {};

K3D.bin.f  = new Float32Array(1);
K3D.bin.fb = new Uint8Array(K3D.bin.f.buffer);

K3D.bin.rf		= function(buff, off) { var f = K3D.bin.f, fb = K3D.bin.fb; for(var i=0; i<4; i++) fb[i] = buff[off+i]; return f[0]; }
K3D.bin.rsl		= function(buff, off) { return buff[off] | buff[off+1]<<8; }
K3D.bin.ril		= function(buff, off) { return buff[off] | buff[off+1]<<8 | buff[off+2]<<16 | buff[off+3]<<24; }
K3D.bin.rASCII0 = function(buff, off) { var s = ""; while(buff[off]!=0) s += String.fromCharCode(buff[off++]); return s; }


K3D.bin.wf		= function(buff, off, v) { var f=new Float32Array(buff.buffer, off, 1); f[0]=v; }
K3D.bin.wsl		= function(buff, off, v) { buff[off]=v; buff[off+1]=v>>8; }
K3D.bin.wil		= function(buff, off, v) { buff[off]=v; buff[off+1]=v>>8; buff[off+2]=v>>16; buff[off+3]>>24; }
K3D.parse = {};

K3D.parse._buffToStr = function(buff)
{
    var a = new Uint8Array(buff);
    var s = "";
    for(var i=0; i<a.length; i++) s = s.concat(String.fromCharCode(a[i]));
    return s;
}

K3D.parse._strToBuff = function(str)
{
    var buf = new ArrayBuffer(str.length);
    var bufView = new Uint8Array(buf);
    for (var i=0; i<str.length; i++) bufView[i] = str.charCodeAt(i);
    return buf;
}

K3D.parse._readLine = function(a, off)	// Uint8Array, offset
{
    var s = "";
    while(a[off] != 10) s += String.fromCharCode(a[off++]);
    return s;
}
K3D.parse.fromJSON = function(buff)
{
    var json = JSON.parse(K3D.parse._buffToStr(buff));
    return json;
}

K3D.parse.toJSON = function(object)
{
    var str = JSON.stringify(object);
    return K3D.parse._strToBuff(str);
}

K3D.parse.fromOBJ = function(buff)
{
    var res = {};
    res.groups = {};

    res.c_verts = [];
    res.c_uvt	= [];
    res.c_norms = [];

    res.i_verts = [];
    res.i_uvt   = [];
    res.i_norms = [];

    var cg = {from: 0, to:0};	// current group
    var off = 0;
    var a = new Uint8Array(buff);

    while(off < a.length)
    {
        var line = K3D.parse._readLine(a, off);
        off += line.length + 1;
        line = line.replace(/ +(?= )/g,'');
        line = line.replace(/(^\s+|\s+$)/g, '');
        var cds = line.split(" ");
        if(cds[0] == "g")
        {
            cg.to = res.i_verts.length;
            if(res.groups[cds[1]] == null) res.groups[cds[1]] = {from:res.i_verts.length, to:0};
            cg = res.groups[cds[1]];
        }
        if(cds[0] == "v")
        {
            var x = parseFloat(cds[1]);
            var y = parseFloat(cds[2]);
            var z = parseFloat(cds[3]);
            res.c_verts.push(x,y,z);
        }
        if(cds[0] == "vt")
        {
            var x = parseFloat(cds[1]);
            var y = 1-parseFloat(cds[2]);
            res.c_uvt.push(x,y);
        }
        if(cds[0] == "vn")
        {
            var x = parseFloat(cds[1]);
            var y = parseFloat(cds[2]);
            var z = parseFloat(cds[3]);
            res.c_norms.push(x,y,z);
        }
        if(cds[0] == "f")
        {
            var v0a = cds[1].split("/"), v1a = cds[2].split("/"), v2a = cds[3].split("/");
            var vi0 = parseInt(v0a[0])-1, vi1 = parseInt(v1a[0])-1, vi2 = parseInt(v2a[0])-1;
            var ui0 = parseInt(v0a[1])-1, ui1 = parseInt(v1a[1])-1, ui2 = parseInt(v2a[1])-1;
            var ni0 = parseInt(v0a[2])-1, ni1 = parseInt(v1a[2])-1, ni2 = parseInt(v2a[2])-1;

            var vlen = res.c_verts.length/3, ulen = res.c_uvt.length/2, nlen = res.c_norms.length/3;
            if(vi0<0) vi0 = vlen + vi0+1; if(vi1<0) vi1 = vlen + vi1+1;	if(vi2<0) vi2 = vlen + vi2+1;
            if(ui0<0) ui0 = ulen + ui0+1; if(ui1<0) ui1 = ulen + ui1+1;	if(ui2<0) ui2 = ulen + ui2+1;
            if(ni0<0) ni0 = nlen + ni0+1; if(ni1<0) ni1 = nlen + ni1+1;	if(ni2<0) ni2 = nlen + ni2+1;

            res.i_verts.push(vi0, vi1, vi2);  //cg.i_verts.push(vi0, vi1, vi2)
            res.i_uvt  .push(ui0, ui1, ui2);  //cg.i_uvt  .push(ui0, ui1, ui2);
            res.i_norms.push(ni0, ni1, ni2);  //cg.i_norms.push(ni0, ni1, ni2);
            if(cds.length == 5)
            {
                var v3a = cds[4].split("/");
                var vi3 = parseInt(v3a[0])-1, ui3 = parseInt(v3a[1])-1, ni3 = parseInt(v3a[2])-1;
                if(vi3<0) vi3 = vlen + vi3+1;
                if(ui3<0) ui3 = ulen + ui3+1;
                if(ni3<0) ni3 = nlen + ni3+1;
                res.i_verts.push(vi0, vi2, vi3);  //cg.i_verts.push(vi0, vi2, vi3);
                res.i_uvt  .push(ui0, ui2, ui3);  //cg.i_uvt  .push(ui0, ui2, ui3);
                res.i_norms.push(ni0, ni2, ni3);  //cg.i_norms.push(ni0, ni2, ni3);
            }
        }
    }
    cg.to = res.i_verts.length;

    return res;
}


K3D.parse.fromMD2 = function(buff)
{
    buff = new Uint8Array(buff);
    var res = {};
    var head = {};
    //res.head = head;
    head.ident			= K3D.bin.ril(buff,  0);             /* magic number: "IDP2" */
    head.version		= K3D.bin.ril(buff,  4);             /* version: must be 8 */

    head.skinwidth		= K3D.bin.ril(buff,  8);             /* texture width */
    head.skinheight		= K3D.bin.ril(buff, 12);             /* texture height */

    head.framesize		= K3D.bin.ril(buff, 16);             /* size in bytes of a frame */

    head.num_skins		= K3D.bin.ril(buff, 20);             /* number of skins */
    head.num_vertices	= K3D.bin.ril(buff, 24);             /* number of vertices per frame */
    head.num_st			= K3D.bin.ril(buff, 28);             /* number of texture coordinates */
    head.num_tris		= K3D.bin.ril(buff, 32);             /* number of triangles */
    head.num_glcmds		= K3D.bin.ril(buff, 36);             /* number of opengl commands */
    head.num_frames		= K3D.bin.ril(buff, 40);             /* number of frames */

    head.offset_skins	= K3D.bin.ril(buff, 44);             /* offset skin data */
    head.offset_st		= K3D.bin.ril(buff, 48);             /* offset texture coordinate data */
    head.offset_tris	= K3D.bin.ril(buff, 52);             /* offset triangle data */
    head.offset_frames	= K3D.bin.ril(buff, 56);             /* offset frame data */
    head.offset_glcmds	= K3D.bin.ril(buff, 60);             /* offset OpenGL command data */
    head.offset_end		= K3D.bin.ril(buff, 64);             /* offset end of file */

    var off = head.offset_st;
    res.c_uvt = [];
    for(var i=0; i<head.num_st; i++)
    {
        var x = K3D.bin.rsl(buff, off  )/head.skinwidth;
        var y = K3D.bin.rsl(buff, off+2)/head.skinheight;
        res.c_uvt.push(x,y);  off += 4;
    }

    var off = head.offset_tris;
    var vi = [], ti = [];
    res.i_verts = vi;
    res.i_uvt = ti;
    //res.tris = {i_verts : vi, i_uvt : ti};
    for(var i=0; i<head.num_tris; i++)
    {
        vi.push(K3D.bin.rsl(buff, off  ), K3D.bin.rsl(buff, off+2), K3D.bin.rsl(buff, off+4 ));
        ti.push(K3D.bin.rsl(buff, off+6), K3D.bin.rsl(buff, off+8), K3D.bin.rsl(buff, off+10));
        off += 12;
    }

    var off = head.offset_skins;
    res.skins = [];
    for(var i=0; i<head.num_skins; i++)
    {
        res.skins.push(K3D.bin.rASCII0(buff, off));
        off += 64;
    }

    var off = head.offset_frames;
    res.frames = [];
    var nms = K3D.parse.fromMD2._normals;
    for(var i=0; i<head.num_frames; i++)
    {
        var fr = {};
        var sx = K3D.bin.rf(buff, off), sy = K3D.bin.rf(buff, off+4), sz = K3D.bin.rf(buff, off+8);  off += 12;
        var tx = K3D.bin.rf(buff, off), ty = K3D.bin.rf(buff, off+4), tz = K3D.bin.rf(buff, off+8);  off += 12;
        fr.name		 = K3D.bin.rASCII0(buff, off); off += 16;
        fr.verts	 = [];
        fr.norms	 = [];

        for(var j=0; j<head.num_vertices; j++)
        {
            fr.verts.push(buff[off]*sx+tx, buff[off+1]*sy+ty, buff[off+2]*sz+tz);
            fr.norms.push(nms[3*buff[off+3]], nms[3*buff[off+3]+1], nms[3*buff[off+3]+2]);
            off += 4;
        }
        res.frames.push(fr);
    }
    return res;
}



/*
 static MD2 normals
 */

K3D.parse.fromMD2._normals =
    [
        -0.525731,  0.000000,  0.850651,
        -0.442863,  0.238856,  0.864188,
        -0.295242,  0.000000,  0.955423,
        -0.309017,  0.500000,  0.809017,
        -0.162460,  0.262866,  0.951056,
        0.000000,  0.000000,  1.000000,
        0.000000,  0.850651,  0.525731,
        -0.147621,  0.716567,  0.681718,
        0.147621,  0.716567,  0.681718,
        0.000000,  0.525731,  0.850651,
        0.309017,  0.500000,  0.809017,
        0.525731,  0.000000,  0.850651,
        0.295242,  0.000000,  0.955423,
        0.442863,  0.238856,  0.864188,
        0.162460,  0.262866,  0.951056,
        -0.681718,  0.147621,  0.716567,
        -0.809017,  0.309017,  0.500000,
        -0.587785,  0.425325,  0.688191,
        -0.850651,  0.525731,  0.000000,
        -0.864188,  0.442863,  0.238856,
        -0.716567,  0.681718,  0.147621,
        -0.688191,  0.587785,  0.425325,
        -0.500000,  0.809017,  0.309017,
        -0.238856,  0.864188,  0.442863,
        -0.425325,  0.688191,  0.587785,
        -0.716567,  0.681718, -0.147621,
        -0.500000,  0.809017, -0.309017,
        -0.525731,  0.850651,  0.000000,
        0.000000,  0.850651, -0.525731,
        -0.238856,  0.864188, -0.442863,
        0.000000,  0.955423, -0.295242,
        -0.262866,  0.951056, -0.162460,
        0.000000,  1.000000,  0.000000,
        0.000000,  0.955423,  0.295242,
        -0.262866,  0.951056,  0.162460,
        0.238856,  0.864188,  0.442863,
        0.262866,  0.951056,  0.162460,
        0.500000,  0.809017,  0.309017,
        0.238856,  0.864188, -0.442863,
        0.262866,  0.951056, -0.162460,
        0.500000,  0.809017, -0.309017,
        0.850651,  0.525731,  0.000000,
        0.716567,  0.681718,  0.147621,
        0.716567,  0.681718, -0.147621,
        0.525731,  0.850651,  0.000000,
        0.425325,  0.688191,  0.587785,
        0.864188,  0.442863,  0.238856,
        0.688191,  0.587785,  0.425325,
        0.809017,  0.309017,  0.500000,
        0.681718,  0.147621,  0.716567,
        0.587785,  0.425325,  0.688191,
        0.955423,  0.295242,  0.000000,
        1.000000,  0.000000,  0.000000,
        0.951056,  0.162460,  0.262866,
        0.850651, -0.525731,  0.000000,
        0.955423, -0.295242,  0.000000,
        0.864188, -0.442863,  0.238856,
        0.951056, -0.162460,  0.262866,
        0.809017, -0.309017,  0.500000,
        0.681718, -0.147621,  0.716567,
        0.850651,  0.000000,  0.525731,
        0.864188,  0.442863, -0.238856,
        0.809017,  0.309017, -0.500000,
        0.951056,  0.162460, -0.262866,
        0.525731,  0.000000, -0.850651,
        0.681718,  0.147621, -0.716567,
        0.681718, -0.147621, -0.716567,
        0.850651,  0.000000, -0.525731,
        0.809017, -0.309017, -0.500000,
        0.864188, -0.442863, -0.238856,
        0.951056, -0.162460, -0.262866,
        0.147621,  0.716567, -0.681718,
        0.309017,  0.500000, -0.809017,
        0.425325,  0.688191, -0.587785,
        0.442863,  0.238856, -0.864188,
        0.587785,  0.425325, -0.688191,
        0.688191,  0.587785, -0.425325,
        -0.147621,  0.716567, -0.681718,
        -0.309017,  0.500000, -0.809017,
        0.000000,  0.525731, -0.850651,
        -0.525731,  0.000000, -0.850651,
        -0.442863,  0.238856, -0.864188,
        -0.295242,  0.000000, -0.955423,
        -0.162460,  0.262866, -0.951056,
        0.000000,  0.000000, -1.000000,
        0.295242,  0.000000, -0.955423,
        0.162460,  0.262866, -0.951056,
        -0.442863, -0.238856, -0.864188,
        -0.309017, -0.500000, -0.809017,
        -0.162460, -0.262866, -0.951056,
        0.000000, -0.850651, -0.525731,
        -0.147621, -0.716567, -0.681718,
        0.147621, -0.716567, -0.681718,
        0.000000, -0.525731, -0.850651,
        0.309017, -0.500000, -0.809017,
        0.442863, -0.238856, -0.864188,
        0.162460, -0.262866, -0.951056,
        0.238856, -0.864188, -0.442863,
        0.500000, -0.809017, -0.309017,
        0.425325, -0.688191, -0.587785,
        0.716567, -0.681718, -0.147621,
        0.688191, -0.587785, -0.425325,
        0.587785, -0.425325, -0.688191,
        0.000000, -0.955423, -0.295242,
        0.000000, -1.000000,  0.000000,
        0.262866, -0.951056, -0.162460,
        0.000000, -0.850651,  0.525731,
        0.000000, -0.955423,  0.295242,
        0.238856, -0.864188,  0.442863,
        0.262866, -0.951056,  0.162460,
        0.500000, -0.809017,  0.309017,
        0.716567, -0.681718,  0.147621,
        0.525731, -0.850651,  0.000000,
        -0.238856, -0.864188, -0.442863,
        -0.500000, -0.809017, -0.309017,
        -0.262866, -0.951056, -0.162460,
        -0.850651, -0.525731,  0.000000,
        -0.716567, -0.681718, -0.147621,
        -0.716567, -0.681718,  0.147621,
        -0.525731, -0.850651,  0.000000,
        -0.500000, -0.809017,  0.309017,
        -0.238856, -0.864188,  0.442863,
        -0.262866, -0.951056,  0.162460,
        -0.864188, -0.442863,  0.238856,
        -0.809017, -0.309017,  0.500000,
        -0.688191, -0.587785,  0.425325,
        -0.681718, -0.147621,  0.716567,
        -0.442863, -0.238856,  0.864188,
        -0.587785, -0.425325,  0.688191,
        -0.309017, -0.500000,  0.809017,
        -0.147621, -0.716567,  0.681718,
        -0.425325, -0.688191,  0.587785,
        -0.162460, -0.262866,  0.951056,
        0.442863, -0.238856,  0.864188,
        0.162460, -0.262866,  0.951056,
        0.309017, -0.500000,  0.809017,
        0.147621, -0.716567,  0.681718,
        0.000000, -0.525731,  0.850651,
        0.425325, -0.688191,  0.587785,
        0.587785, -0.425325,  0.688191,
        0.688191, -0.587785,  0.425325,
        -0.955423,  0.295242,  0.000000,
        -0.951056,  0.162460,  0.262866,
        -1.000000,  0.000000,  0.000000,
        -0.850651,  0.000000,  0.525731,
        -0.955423, -0.295242,  0.000000,
        -0.951056, -0.162460,  0.262866,
        -0.864188,  0.442863, -0.238856,
        -0.951056,  0.162460, -0.262866,
        -0.809017,  0.309017, -0.500000,
        -0.864188, -0.442863, -0.238856,
        -0.951056, -0.162460, -0.262866,
        -0.809017, -0.309017, -0.500000,
        -0.681718,  0.147621, -0.716567,
        -0.681718, -0.147621, -0.716567,
        -0.850651,  0.000000, -0.525731,
        -0.688191,  0.587785, -0.425325,
        -0.587785,  0.425325, -0.688191,
        -0.425325,  0.688191, -0.587785,
        -0.425325, -0.688191, -0.587785,
        -0.587785, -0.425325, -0.688191,
        -0.688191, -0.587785, -0.425325
    ];

K3D.parse.fromCollada = function(buff)
{
    var str = K3D.parse._buffToStr(buff);
    var xml = new DOMParser().parseFromString(str,"text/xml");
    xml = xml.childNodes[0];
    var resp = {};

    //console.log(xml);

    var ass = xml.getElementsByTagName("asset"             )[0];
    var geo = xml.getElementsByTagName("library_geometries")[0];
    var ima = xml.getElementsByTagName("library_images"    )[0];
    var mat = xml.getElementsByTagName("library_materials" )[0];
    var eff = xml.getElementsByTagName("library_effects"   )[0];

    //console.log(xml);
    if(ass) resp.asset 		= K3D.parse.fromCollada._asset        (ass);
    if(geo) resp.geometries = K3D.parse.fromCollada._libGeometries(geo);
    if(ima) resp.images     = K3D.parse.fromCollada._libImages    (ima);
    if(mat) resp.materials  = K3D.parse.fromCollada._libMaterials (mat);
    if(eff) resp.effects    = K3D.parse.fromCollada._libEffects   (eff);
    return resp;
}

K3D.parse.fromCollada._asset = function(xml)
{
    //console.log(xml);
    return {
        created : xml.getElementsByTagName("created" )[0].textContent,
        modified: xml.getElementsByTagName("modified")[0].textContent,
        up_axis : xml.getElementsByTagName("up_axis" )[0].textContent
    };
}

K3D.parse.fromCollada._libGeometries = function(xml)
{
    xml = xml.getElementsByTagName("geometry");
    var res = [];
    for(var i=0; i<xml.length; i++)
    {
        var g = xml[i];
        var o = K3D.parse.fromCollada._getMesh(g.getElementsByTagName("mesh")[0]);
        res.push(o);
    }
    return res;
}

K3D.parse.fromCollada._getMesh = function(mesh)
{
    //console.log(mesh);
    var res = {};
    var ss = mesh.getElementsByTagName("source");
    var sources = res.sources = {};
    for(var i=0; i<ss.length; i++)
    {
        var farr = ss[i].getElementsByTagName("float_array")[0].textContent.split(" ");
        var fl = farr.length - (farr[farr.length-1] == "" ? 1 : 0);
        var arr = new Array(fl);
        for(var j=0; j<fl; j++) arr[j] = parseFloat(farr[j]);
        sources[ss[i].getAttribute("id")] = arr;
    }

    res.triangles = [];
    var tgs = mesh.getElementsByTagName("triangles");
    if(tgs == null) return res;
    for(var i=0; i<tgs.length; i++)
    {
        var t = {};
        var tnode = tgs[i];
        t.material = tnode.getAttribute("material");
        var inputs = tnode.getElementsByTagName("input");
        var inds = [];
        for(var j=0; j<inputs.length; j++)
        {
            var inp = inputs[j], arr = [];
            inds[parseInt(inp.getAttribute("offset"))] = arr;
            var par = inp.getAttribute("semantic");
            t["s_"+par] = (par == "VERTEX") ?
                mesh.getElementsByTagName("vertices")[0].getElementsByTagName("input")[0].getAttribute("source").substring(1)
                : inp.getAttribute("source").substring(1);

            t["i_"+par] = arr;
            var psrc = sources[t["s_"+par]];
        }
        var indices = tnode.getElementsByTagName("p")[0].textContent.split(" ");
        var inum = 3*Math.floor(indices.length/3);
        for(var j=0; j<inum; j++) inds[j%inputs.length].push(parseInt(indices[j]));

        /*
         if(t.s_VERTEX  ) t.u_VERTEX   = K3D.edit.unwrap(t.i_VERTEX  , sources[t.s_VERTEX  ], 3);
         if(t.s_TEXCOORD) t.u_TEXCOORD = K3D.edit.unwrap(t.i_TEXCOORD, sources[t.s_TEXCOORD], 2);
         if(t.s_NORMAL  ) t.u_NORMAL   = K3D.edit.unwrap(t.i_NORMAL  , sources[t.s_NORMAL  ], 3);
         //*/
        //if(t.s_TEXCOORD) for(var j=1; j<t.u_TEXCOORD.length; j+=2) t.u_TEXCOORD[j] = 1 - t.u_TEXCOORD[j];

        /*
         t.u_INDEX = new Array(t.i_VERTEX.length);
         for(var j=0; j<t.i_VERTEX.length; j++) t.u_INDEX[j] = j;
         */

        res.triangles.push(t);
    }
    return res;
}

K3D.parse.fromCollada._libImages = function(xml)
{
    xml = xml.getElementsByTagName("image");
    var res = {};
    for(var i=0; i<xml.length; i++)
    {
        res[xml[i].getAttribute("id")] = xml[i].getElementsByTagName("init_from")[0].textContent;
    }
    return res;
}

K3D.parse.fromCollada._libMaterials = function(xml)
{
    xml = xml.getElementsByTagName("material");
    var res = {};
    for(var i=0; i<xml.length; i++)
    {
        res[xml[i].getAttribute("name")] = xml[i].getElementsByTagName("instance_effect")[0].getAttribute("url").substring(1);
    }
    return res;
}

K3D.parse.fromCollada._libEffects = function(xml)
{
    xml = xml.getElementsByTagName("effect");
    var res = {};
    for(var i=0; i<xml.length; i++)
    {
        var eff = {};
        var params = xml[i].getElementsByTagName("newparam");
        for(var j=0; j<params.length; j++)
        {
            var srf = params[j].getElementsByTagName("surface")[0];
            if(srf) eff.surface = srf.getElementsByTagName("init_from")[0].textContent;
        }
        res[xml[i].getAttribute("id")] = eff;
    }
    return res;
}





K3D.parse.from3DS = function(buff)
{
    buff = new Uint8Array(buff);
    var res = {};
    if(K3D.bin.rsl(buff, 0) != 0x4d4d) return null;
    var lim = K3D.bin.ril(buff, 2);

    var off = 6;
    while(off < lim)
    {
        var cid = K3D.bin.rsl(buff, off);
        var lng = K3D.bin.ril(buff, off+2);
        //console.log(cid.toString(16), lng);

        if(cid == 0x3d3d) res.edit = K3D.parse.from3DS._edit3ds(buff, off, lng);
        if(cid == 0xb000) res.keyf = K3D.parse.from3DS._keyf3ds(buff, off, lng);

        off += lng;
    }
    return res;
}

K3D.parse.from3DS._edit3ds = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = {};
    var off = coff+6;
    while(off < coff+clng)
    {
        var cid = K3D.bin.rsl(buff, off);
        var lng = K3D.bin.ril(buff, off+2);
        //console.log("\t", cid.toString(16), lng);

        if(cid == 0x4000) { if(res.objects==null) res.objects = []; res.objects.push(K3D.parse.from3DS._edit_object(buff, off, lng)); }
        //if(cid == 0xb000) res.KEYF3DS = K3D.parse.from3DS._keyf3ds(buff, off, lng);

        off += lng;
    }
    return res;
}

K3D.parse.from3DS._keyf3ds = function(buff, coff, clng)
{
    var res = {};
    var off = coff+6;
    while(off < coff+clng)
    {
        var cid = K3D.bin.rsl(buff, off);
        var lng = K3D.bin.ril(buff, off+2);
        //console.log("\t\t", cid.toString(16), lng);

        //if(cid == 0x4000) { res.objects.push(K3D.parse.from3DS._edit_object(buff, off, lng)); }
        if(cid == 0xb002) { if(res.desc==null) res.desc = []; res.desc.push(K3D.parse.from3DS._keyf_objdes(buff, off, lng)); }

        off += lng;
    }
    return res;
}

K3D.parse.from3DS._keyf_objdes = function(buff, coff, clng)
{
    var res = {};
    var off = coff+6;
    while(off < coff+clng)
    {
        var cid = K3D.bin.rsl(buff, off);
        var lng = K3D.bin.ril(buff, off+2);
        //console.log("\t\t\t", cid.toString(16), lng);

        if(cid == 0xb010) res.hierarchy = K3D.parse.from3DS._keyf_objhierarch(buff, off, lng);
        if(cid == 0xb011) res.dummy_name = K3D.bin.rASCII0(buff, off+6);
        off += lng;
    }
    return res;
}

K3D.parse.from3DS._keyf_objhierarch = function(buff, coff, clng)
{
    var res = {};
    var off = coff+6;
    res.name = K3D.bin.rASCII0(buff, off);  off += res.name.length+1;
    res.hierarchy = K3D.bin.rsl(buff, off+4);
    return res;
}

K3D.parse.from3DS._edit_object = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = {};
    var off = coff+6;
    res.name = K3D.bin.rASCII0(buff, off);  off += res.name.length+1;
    //console.log(res.name);
    while(off < coff+clng)
    {
        var cid = K3D.bin.rsl(buff, off);
        var lng = K3D.bin.ril(buff, off+2);
        //console.log("\t\t", cid.toString(16), lng);

        if(cid == 0x4100) res.mesh = K3D.parse.from3DS._obj_trimesh(buff, off, lng);
        //if(cid == 0xb000) res.KEYF3DS = K3D.parse.from3DS._keyf3ds(buff, off, lng);

        off += lng;
    }
    return res;
}

K3D.parse.from3DS._obj_trimesh = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = {};
    var off = coff+6;

    while(off < coff+clng)
    {
        var cid = K3D.bin.rsl(buff, off);
        var lng = K3D.bin.ril(buff, off+2);
        //console.log("\t\t\t", cid.toString(16), lng);

        if(cid == 0x4110) res.vertices      = K3D.parse.from3DS._tri_vertexl     (buff, off, lng);
        if(cid == 0x4120) res.indices       = K3D.parse.from3DS._tri_facel1      (buff, off, lng);
        if(cid == 0x4140) res.uvt			= K3D.parse.from3DS._tri_mappingcoors(buff, off, lng);
        if(cid == 0x4160) res.local		    = K3D.parse.from3DS._tri_local       (buff, off, lng);
        off += lng;
    }
    return res;
}

K3D.parse.from3DS._tri_vertexl = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = [];
    var off = coff+6;
    var n = K3D.bin.rsl(buff, off);  off += 2;
    for(var i=0; i<n; i++)
    {
        res.push(K3D.bin.rf(buff, off  ));	res.push(K3D.bin.rf(buff, off+4));	res.push(K3D.bin.rf(buff, off+8));
        off += 12;
    }
    return res;
}

K3D.parse.from3DS._tri_facel1 = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = [];
    var off = coff+6;
    var n = K3D.bin.rsl(buff, off);  off += 2;
    for(var i=0; i<n; i++)
    {
        res.push(K3D.bin.rsl(buff, off  ));
        res.push(K3D.bin.rsl(buff, off+2));
        res.push(K3D.bin.rsl(buff, off+4));
        off += 8;
    }
    return res;
}

K3D.parse.from3DS._tri_mappingcoors = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = [];
    var off = coff+6;
    var n = K3D.bin.rsl(buff, off);  off += 2;
    for(var i=0; i<n; i++)
    {
        res.push(  K3D.bin.rf(buff, off  ));
        res.push(1-K3D.bin.rf(buff, off+4));
        off += 8;
    }
    return res;
}

K3D.parse.from3DS._tri_local = function(buff, coff, clng)	// buffer, chunk offset, length
{
    var res = {};
    var off = coff+6;
    res.X = [K3D.bin.rf(buff, off), K3D.bin.rf(buff, off+4), K3D.bin.rf(buff, off+8)];  off += 12;
    res.Y = [K3D.bin.rf(buff, off), K3D.bin.rf(buff, off+4), K3D.bin.rf(buff, off+8)];  off += 12;
    res.Z = [K3D.bin.rf(buff, off), K3D.bin.rf(buff, off+4), K3D.bin.rf(buff, off+8)];  off += 12;
    res.C = [K3D.bin.rf(buff, off), K3D.bin.rf(buff, off+4), K3D.bin.rf(buff, off+8)];  off += 12;
    return res;
}

K3D.parse.fromBIV = function(buff)
{
    buff = new Uint8Array(buff);
    var res = {};

    var head = {};

    head.id		= K3D.bin.ril(buff,  0);

    head.verS	= K3D.bin.ril(buff,  4);
    head.texS	= K3D.bin.ril(buff,  8);
    head.indS	= K3D.bin.ril(buff, 12);

    head.verO	= K3D.bin.ril(buff, 16);
    head.verL	= K3D.bin.ril(buff, 20);
    head.texO	= K3D.bin.ril(buff, 24);
    head.texL	= K3D.bin.ril(buff, 28);
    head.indO	= K3D.bin.ril(buff, 32);
    head.indL	= K3D.bin.ril(buff, 36);

    if(head.verO != 0) res.vertices = K3D.parse.fromBIV._readFloats(buff, head.verO, head.verL);
    if(head.texO != 0) res.uvt      = K3D.parse.fromBIV._readFloats(buff, head.texO, head.texL);
    if(head.indO != 0) res.indices  = K3D.parse.fromBIV._readInts  (buff, head.indO, head.indL, head.indS);

    return res;
}

K3D.parse.toBIV = function(obj)
{
    var maxi = 0;
    for(var i=0; i<obj.indices.length; i++)	maxi = Math.max(maxi, obj.indices[i]);

    var indS = 32;
    if(maxi<=0xffff) indS = 16;

    var len = 40;
    if(obj.vertices) len+=obj.vertices.length*4;
    if(obj.uvt     ) len+=obj.uvt     .length*4;
    if(obj.indices ) len+=obj.indices .length*indS/8;


    var buff = new Uint8Array(len);

    K3D.bin.wil(buff,  0, 0x6976616e);

    K3D.bin.wil(buff,  4, 32);
    K3D.bin.wil(buff,  8, 32);
    K3D.bin.wil(buff, 12, indS);

    var off = 40;
    if(obj.vertices)
    {
        K3D.bin.wil(buff, 16, off);
        K3D.bin.wil(buff, 20, 4*obj.vertices.length);
        K3D.parse.fromBIV._writeFloats(buff, off, obj.vertices);
        off += 4*obj.vertices.length;
    }
    if(obj.uvt)
    {
        K3D.bin.wil(buff, 24, off);
        K3D.bin.wil(buff, 28, 4*obj.uvt.length);
        K3D.parse.fromBIV._writeFloats(buff, off, obj.uvt);
        off += 4*obj.uvt.length;
    }
    if(obj.indices)
    {
        K3D.bin.wil(buff, 32, off);
        K3D.bin.wil(buff, 36, 4*obj.indices.length);
        K3D.parse.fromBIV._writeInts  (buff, off, obj.indices, indS);
    }
    return buff.buffer;
}

K3D.parse.fromBIV._readFloats = function(buff, off, len)
{
    var arr = [];
    for(var i=0; i<len/4; i++) arr.push( K3D.bin.rf(buff, off+4*i));
    return arr;
}

K3D.parse.fromBIV._writeFloats = function(buff, off, arr)
{
    for(var i=0; i<arr.length; i++) K3D.bin.wf(buff, off+4*i, arr[i]);
}

K3D.parse.fromBIV._readInts   = function(buff, off, len, cs)
{
    var arr = [];
    for(var i=0; i<len/4; i++)
    {
        if(cs==16) arr.push( K3D.bin.rsl(buff, off+2*i));
        if(cs==32) arr.push( K3D.bin.ril(buff, off+4*i));
    }
    return arr;
}

K3D.parse.fromBIV._writeInts   = function(buff, off, arr, cs)
{
    for(var i=0; i<arr.length; i++)
    {
        if(cs==16) K3D.bin.wsl(buff, off+2*i, arr[i]);
        if(cs==32) K3D.bin.wil(buff, off+4*i, arr[i]);
    }
}
K3D.gen = {};

K3D.gen.Plane = function(sw, sh, tsw, tsh)
{
    if(!tsw) tsw = 1;
    if(!tsh) tsh = 1;
    var r = {verts:[], inds:[], uvt:[]};
    var ssw = sw+1, ssh = sh+1
    for(var i=0; i<ssh; i++)
    {
        for(var j=0; j<ssw; j++)
        {
            var x = -1 + j*(2/sw);
            var y = -1 + i*(2/sh);
            r.verts.push(x, y, 0);
            r.uvt.push(tsw*j/sw, tsh*i/sh);
            if(i<sh && j<sw)
                r.inds.push(i*ssw+j, i*ssw+j+1, (i+1)*ssw+j,   i*ssw+j+1, (i+1)*ssw+j, (i+1)*ssw+j+1);
        }
    }
    return r;
}
K3D.gen.Cube = function()
{
    var r = {
        verts:[	-1, 1,-1,   1, 1,-1,  -1,-1,-1,   1,-1,-1, // front
            -1, 1, 1,   1, 1, 1,  -1,-1, 1,   1,-1, 1, // back

            -1, 1, 1,  -1, 1,-1,  -1,-1, 1,  -1,-1,-1, // left
            1, 1, 1,   1, 1,-1,   1,-1, 1,   1,-1,-1, // right

            -1, 1,-1,   1, 1,-1,  -1, 1, 1,   1, 1, 1, // top
            -1,-1,-1,   1,-1,-1,  -1,-1, 1,   1,-1, 1  // bottom
        ],
        inds:[	0,1,2, 1,2,3, 4,5,6, 5,6,7,
            8,9,10, 9,10,11, 12,13,14, 13,14,15,
            16,17,18, 17,18,19, 20,21,22, 21,22,23
        ],
        uvt:[
            1/4,1/4,  2/4,1/4,  1/4,2/4,  2/4,2/4, // front
            4/4,1/4,  3/4,1/4,  4/4,2/4,  3/4,2/4, // back

            0/4,1/4,  1/4,1/4,  0/4,2/4,  1/4,2/4, // left
            3/4,1/4,  2/4,1/4,  3/4,2/4,  2/4,2/4, // right

            1/4,1/4,  2/4,1/4,  1/4,0/4,  2/4,0/4, // top
            1/4,2/4,  2/4,2/4,  1/4,3/4,  2/4,3/4, // bottom
        ]
    };
    return r;
};

K3D.gen.Sphere = function(sx, sy){
    var r = {verts:[], inds:[], uvt:[]};

    var dx = 2*Math.PI/sx;
    var dy = Math.PI/sy;
    var nx = sx+1, ny = sy+1;
    for(var i=0; i<ny; i++)	// rows
    {
        for(var j=0; j<nx; j++) // cols
        {
            var lat = -Math.PI/2 + i*Math.PI/sy;
            var lon =  j*2*Math.PI/sx;
            var x = Math.cos(lat) * Math.cos(lon);
            var y = Math.sin(lat);
            var z = Math.cos(lat) * Math.sin(lon);

            r.verts.push(x,y,z);
            r.uvt.push(j/sx, i/sy);
            if(i<sy && j<sx)          // 6 indices for 2 triangles
                r.inds.push(nx*i+j, nx*i+j+1, nx*(i+1)+j, nx*i+j+1, nx*(i+1)+j, nx*(i+1)+j+1);
        }
    }
    return r;
};

K3D.mat = {};

K3D.mat.scale = function(x,y,z){
    return [
        x,0,0,0,
        0,y,0,0,
        0,0,z,0,
        0,0,0,1
    ];
};

K3D.mat.translate = function(x,y,z){
    return [
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        x,y,z,1
    ];
};

K3D.mat.rotateDeg = function(x,y,z){
    var r = Math.PI/180;
    return K3D.mat.rotate(x*r, y*r, z*r);
};

K3D.mat.rotate = function(x,y,z){
    var m = [
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        0,0,0,1
    ];
    var a =  x;	// alpha
    var b =  y;	// beta
    var g =  z;	// gama

    var ca = Math.cos(a), cb = Math.cos(b), cg = Math.cos(g);
    var sa = Math.sin(a), sb = Math.sin(b), sg = Math.sin(g);

    m[0] = cb*cg;				m[1] = -cb*sg;					m[2 ] = sb;
    m[4] = (ca*sg+sa*sb*cg);	m[5] = (ca*cg-sa*sb*sg);		m[6 ] = -sa*cb;
    m[8] = (sa*sg-ca*sb*cg);	m[9] = (sa*cg+ca*sb*sg);		m[10] = ca*cb;

    return m;
};


K3D.edit = {};

K3D.edit.interpolate = function(a, b, d, t){
    for(var i=0; i<a.length; i++) d[i] = a[i] + t*(b[i] - a[i]);
};


K3D.edit.transform = function(a, m){
    for(var i=0; i<a.length; i+=3)    {
        var x = a[i], y = a[i+1], z = a[i+2];
        a[i+0] = m[0]*x + m[4]*y + m[8 ]*z + m[12];
        a[i+1] = m[1]*x + m[5]*y + m[9 ]*z + m[13];
        a[i+2] = m[2]*x + m[6]*y + m[10]*z + m[14];
    }
};

// starting indices, starting coordinates, coordinates per index

K3D.edit.unwrap = function(ind, crd, cpi){
    var ncrd = new Array(Math.floor(ind.length/3)*cpi);
    for(var i=0; i<ind.length; i++)
    {
        for(var j=0; j<cpi; j++)
        {
            ncrd[i*cpi+j] = crd[ind[i]*cpi+j];
        }
    }
    return ncrd;
};

// current indices, new indices, current array, coordinates per vertex

K3D.edit.remap = function(ind, nind, arr, cpi){
    var ncrd = new Array(arr.length);
    for(var i=0; i<ind.length; i++)
    {
        for(var j=0; j<cpi; j++)
        {
            ncrd[nind[i]*cpi+j] = arr[ind[i]*cpi+j];
        }
    }
    return ncrd;
};

K3D.utils = {};

K3D.utils.getAABB = function(vts)
{
    var minx, miny, minz, maxx, maxy, maxz;
    minx = miny = minz = 999999999;
    maxx = maxy = maxz = -minx;

    for(var i=0; i<vts.length; i+=3)
    {
        var vx = vts[i+0];
        var vy = vts[i+1];
        var vz = vts[i+2];
        if(vx<minx) minx = vx;  if(vx>maxx) maxx = vx;
        if(vy<miny) miny = vy;  if(vy>maxy) maxy = vy;
        if(vz<minz) minz = vz;  if(vy>maxz) maxz = vz;
    }
    return {min:{x:minx, y:miny, z:minz}, max:{x:maxx, y:maxy, z:maxz}};
};

export {K3D};