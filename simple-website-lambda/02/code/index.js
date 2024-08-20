exports.handler = (event, context, callback) => {
   // TODO implement
   console.log(event.key1);
   console.log(event.key2);
   console.log(event.key3);
   callback(null, 'Lambda test');


 var error = new Error("There is error in code");
   callback(error);
};

