import { NextRequest, NextResponse } from 'next/server';
import { v2 as cloudinary } from 'cloudinary';
import { auth } from '@clerk/nextjs/server';

// Configuration
cloudinary.config({ 
    cloud_name: process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME, 
    api_key: process.env.CLOUDINARY_API_KEY, 
    api_secret: process.env.CLOUDINARY_API_SECRET
});

interface CloudinaryUploadResult {
    public_id: string
    [key: string]: unknown
}

export async function POST(request: NextRequest) {
    const {userId} = await auth()

    if(!userId) {
        return NextResponse.json({error: "User is not logged in"}, {status: 401})
    }

    try {
        const formData = await request.formData()       //grab the form data from the frontend
        const file = formData.get("file") as File | null    //grab the file from the formdata

        if(!file) {
            return NextResponse.json({error: "No file uploaded"}, {status: 400})
        }

        //now grab the array buffer from the file, create a new buffer and then upload it to cloudinary
        const bytes = await file.arrayBuffer()
        const buffer = Buffer.from(bytes)       //create a buffer from the bytes that are grabbed from file

        const result = await new Promise<CloudinaryUploadResult>(
            (resolve, reject) => {
                const uploadStream = cloudinary.uploader.upload_stream(
                    {folder: "next-cloudinary-uploads"},
                    (error, result) => {
                        if(error) reject(error)
                        else resolve(result as CloudinaryUploadResult)
                    }
                )
                uploadStream.end(buffer)
            }
        )

        return NextResponse.json({publicId: result.public_id}, {status: 200})
    } catch (error) {
        console.log("Upload image failed", error);
        return NextResponse.json({error: "Upload image failed"}, {status: 500})
    }
}