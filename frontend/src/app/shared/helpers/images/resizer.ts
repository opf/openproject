//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

function dataURItoBlob(dataURI:string) {
  const bytes = dataURI.split(',')[0].includes('base64')
    ? atob(dataURI.split(',')[1])
    : unescape(dataURI.split(',')[1]);
  const mime = dataURI.split(',')[0].split(':')[1].split(';')[0];
  const max = bytes.length;
  const ia = new Uint8Array(max);
  for (let i = 0; i < max; i += 1) {
    ia[i] = bytes.charCodeAt(i);
  }
  return new Blob([ia], { type: mime });
}

/**
 * Resize an image to the given max dimension, returning the data URL and a blob
 * Based on https://stackoverflow.com/a/39235724/420614
 *
 * @param {maxSize} Max width or height
 * @param {HTMLImageElement} Input image
 */
export function resizeImage(maxSize:number, image:HTMLImageElement):[string, Blob] {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d')!;

  let { width } = image;
  let { height } = image;

  if (width > height) {
    if (width > maxSize) {
      height *= maxSize / width;
      width = maxSize;
    }
  } else if (height > maxSize) {
    width *= maxSize / height;
    height = maxSize;
  }

  canvas.width = width;
  canvas.height = height;
  ctx.drawImage(image, 0, 0, width, height);
  const dataUrl = canvas.toDataURL('image/jpeg');
  return [dataUrl, dataURItoBlob(dataUrl)];
}

/**
 * Resize a file input to the given max dimension, returning the data URL and a blob
 *
 * @param maxSize Max width or height
 * @param file Input file
 */
export function resizeFile(maxSize:number, file:File):Promise<[string, Blob]> {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = (readerEvent:ProgressEvent<FileReader>) => {
      const image = new Image();
      image.onload = () => resolve(resizeImage(maxSize, image));
      image.src = readerEvent.target?.result as string;
    };
    reader.readAsDataURL(file);
  });
}
