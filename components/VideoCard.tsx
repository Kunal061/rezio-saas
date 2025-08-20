import React, {useState, useEffect, useCallback} from 'react'
import {getCldImageUrl, getCldVideoUrl} from "next-cloudinary"
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import {Download, Clock, FileDown, FileUp} from "lucide-react"
import { filesize } from 'filesize'
import { Video } from '@/app/generated/prisma'

dayjs.extend(relativeTime)


function videoCard() {
  return (
    <div>videoCard</div>
  )
}

export default videoCard