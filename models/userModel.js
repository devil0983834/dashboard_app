const mongoose = require('mongoose');
const bcrypt = require('bcrypt');



const userSchema = new mongoose.Schema({
    email: { type: String, required: true,unique: true},
    displayName: { type: String, required: false },
    phoneNumber:{ type: String, required: false },
    city: { type: String, required: false},
    age: { type: Number, required: false},
    code: { type: Number, required: false},
    apiRead:{ type: String, required: false},
    apiWrite:{ type: String, required: false}
  });





module.exports = mongoose.model('user',userSchema);