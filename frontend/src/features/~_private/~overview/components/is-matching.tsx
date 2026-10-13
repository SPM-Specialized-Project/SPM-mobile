
import React from 'react'

import localImage from './image.png'

/**
 * Minimal `IsMatching` component — shows a friendly illustration and a small
 * "Vui lòng đợi ..." caption. The original design used a decorative image;
 * this component recreates a lightweight SVG approximation so it works without
 * adding new image files to the repo.
 */
export function IsMatching({ src }: { src?: string }) {
  const imageSrc = src ?? localImage
  return (
    <div className="flex flex-col items-center justify-center py-6">
      <div className="mx-auto w-60">
        {/* Prefer an external image placed in public/images/is-matching.png
						If the image is not present, the browser will show the alt text. */}
        <img src={imageSrc} alt="Is matching" className="mx-auto" />
      </div>

      <div className="mt-4 text-center text-gray-600">
        {/* <div className="text-base font-medium">{message}</div> */}
      </div>
    </div>
  )
}

export default IsMatching
