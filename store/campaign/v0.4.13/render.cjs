// Final-format export only: SVG typesetting -> exact-size sRGB upload files.
const fs=require('fs'),path=require('path'),sharp=require('sharp'),crypto=require('crypto');
const root=__dirname, out=path.join(root,'upload');fs.mkdirSync(out,{recursive:true});
(async()=>{
 const jobs=JSON.parse(fs.readFileSync(process.argv[2]));const manifest=[];
 for(const j of jobs){
  const image=sharp(fs.readFileSync(j.svg)).resize(j.width,j.height).flatten({background:'#FFF8EB'}).removeAlpha().toColourspace('srgb');
  let buffer,filename;
  if(j.name.includes('hero')){buffer=await image.png({compressionLevel:9}).toBuffer();filename=j.name+'.png';if(buffer.length>2048000)throw Error('Hero too large');}
  else {
   filename=j.name+'.png';
   buffer=await image.clone().png({compressionLevel:9}).toBuffer();
   // PNG palette compression keeps screen labels crisp and avoids JPEG halos.
   if(buffer.length>=150000){
    for(const colours of [256,192,128]){
     buffer=await image.clone().png({compressionLevel:9,palette:true,colours,dither:0.25,effort:10}).toBuffer();
     if(buffer.length<149000)break;
    }
   }
   if(buffer.length>=150000)throw Error('Screen PNG too large: '+filename);
  }
  fs.writeFileSync(path.join(out,filename),buffer);manifest.push({file:filename,width:j.width,height:j.height,bytes:buffer.length});
 }
 const icon=path.join(root,'source/rider-icon.png');
 const cover=await sharp(icon).resize(500,500).removeAlpha().toColourspace('srgb').png({compressionLevel:9}).toBuffer();if(cover.length>=300000)throw Error('Cover too large');fs.writeFileSync(path.join(out,'02-cover-500.png'),cover);manifest.push({file:'02-cover-500.png',width:500,height:500,bytes:cover.length});
 const rgb=await sharp(icon).resize(128,128).removeAlpha().toColourspace('srgb').raw().toBuffer();
 for(const limited of [false,true]){const data=Buffer.from(rgb);if(limited)for(let i=0;i<data.length;i++)data[i]=Math.round(data[i]/85)*85;
  const buffer=await sharp(data,{raw:{width:128,height:128,channels:3}}).png({compressionLevel:9}).toBuffer();const file=limited?'03-device-icon-64-color.png':'03-device-icon-24-bit.png';fs.writeFileSync(path.join(out,file),buffer);manifest.push({file,width:128,height:128,bytes:buffer.length,colors:limited?'Garmin RGB cube, at most 64':'24-bit sRGB'});
 }
 for(const item of manifest){const bytes=fs.readFileSync(path.join(out,item.file));item.sha256=crypto.createHash('sha256').update(bytes).digest('hex');item.size_limit_bytes=item.file.includes('hero')?2048000:item.file.includes('cover')?300000:150000;}
 const current=new Set(manifest.map(item=>item.file));
 for(const name of fs.readdirSync(out))if(name.startsWith('04-screen-')&&!current.has(name))fs.unlinkSync(path.join(out,name));
 fs.writeFileSync(path.join(root,'assets.json'),JSON.stringify(manifest,null,2)+'\n');console.log(JSON.stringify(manifest,null,2));
})().catch(e=>{console.error(e);process.exit(1)});
