"use client"
import React, { useState , useEffect, useRef } from 'react'
import { CldImage } from 'next-cloudinary';

const socialFormats = {
  "Instagram square (1:1)": {width: 1080, height: 1080, aspectRatio: "1:1"},
  "Instagram Portrait (4:5)": {width: 1080, height: 1350, aspectRatio: "4:5"},
  "Twitter Post (16:9)": {width: 1200, height: 675, aspectRatio: "16:9"},
  "Twitter Header (3:1)": {width: 1500, height: 500, aspectRatio: "3:1"},
  "Facebook Cover (205:78)": {width: 820, height: 312, aspectRatio: "205:78"},
};

type SocialFormat = keyof typeof socialFormats;

export default function SocialShare() {
  const [uploadedImage, setUploadedImage] = useState<string | null>(null)
  const [selectedFormat, setSelectedFormat] = useState<SocialFormat>("Instagram square (1:1)")
  const [isUploading, setIsUploading] = useState(false)
  const [isTransforming, setIsTransforming] = useState(false)
  const imageRef = useRef<HTMLImageElement>(null)

  useEffect(() => {
    if(uploadedImage) {
      setIsTransforming(true)
    }
  }, [selectedFormat, uploadedImage])

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if(!file) return
    setIsUploading(true)
    const formData = new FormData()
    formData.append("file", file)

    try {
      //send the file to API
      const response = await fetch("api/image-upload", {
        method: "POST",
        body: formData
      })

      //if failed to send
      if(!response.ok) throw new Error("Failed to upload image")

      //get the data
      const data = await response.json()

      //set the uploaded image
      setUploadedImage(data.public_id)
    } catch (error) {
      console.log(error)
      alert("Error uploading image")
    } finally {
      setIsUploading(false)
    }
  }

  const handleDownload = () => {
    //if i do not have reference to the image
    if(!imageRef.current) return

    fetch(imageRef.current.src)   //grab the source of imageRef
    .then((response) => response.blob())    //convert the image response to blob (binary format)
    .then((blob) => {
      const url = window.URL.createObjectURL(blob)    //creating a temp URL in the window to store the blob data
      const link = document.createElement('a')    //create a new 'a' tag element
      link.href = url     //store the created temp URL in the newly created "a" element
      link.download = "image.png"   //tells the browser to download the data when created "a" tag is clicked and name it "image.png" by default
      document.body.appendChild(link)   //attach the link to the document body
      link.click()      //simulate a user click and trigger the download behaviour
      document.body.removeChild(link)   //after download is done, remove the link from the document body
      window.URL.revokeObjectURL(url)     //remove the temporarily created URL in the window
    })
  }

  return (
    <div>SocialShare</div>
  )
}