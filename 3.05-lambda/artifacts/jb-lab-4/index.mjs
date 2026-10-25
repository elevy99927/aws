// Runs every time S3 sends an "object created" event
export const handler = async (event) => {
  console.log('An object was added');
};
