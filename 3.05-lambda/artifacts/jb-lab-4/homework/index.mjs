// Home lab: write the name of each uploaded file to the log
export const handler = async (event) => {
  for (const record of event.Records) {
    // S3 URL-encodes the key in the event: "my photo.jpg" arrives as "my+photo.jpg"
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
    console.log(`An object was added: ${key} (${record.s3.object.size} bytes, bucket ${record.s3.bucket.name})`);
  }
};
