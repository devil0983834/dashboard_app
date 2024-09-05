const app = require('express')();
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const http = require('http').Server(app);
// const WebSocket = require('ws');

// // Sử dụng IP và port khác cho WebSocket server
// const wss = new WebSocket.Server({ host: '192.168.1.20', port: 8080 });

var admin = require("firebase-admin");
var serviceAccount = require("./serviceAccountKey.json");

mongoose.connect('mongodb+srv://vanh:vanh@cluster0.ytw4bms.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0');

const User = require('./models/userModel')

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();

app.get('/', (req, res) => {
  res.send('Welcome to the server!');
});


function createUser(email, password) {
  auth.createUser({
    email: email,
  })
  .then(userRecord => {
    console.log('Successfully created new user:', userRecord.uid);
  })
  .catch(error => {
    console.error('Error creating new user:', error);
  });
}

async function insert(email, displayName, phoneNumber, city, age, code, apiRead, apiWrite){
  User.create({
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      city: city,
      age: age,
      code: code,
      apiRead: apiRead,
      apiWrite: apiWrite
  });
}

app.use(bodyParser.json());
let isChecked = false;

async function checkUser(email, password) {
  try {
    const user = await User.findOne({ email: email });
    if (!user) {
      console.log('Email không tồn tại.');
      isChecked = false;
      return;
    }

    const isMatch = await user.comparePassword(password);
    if (isMatch) {
      console.log('Đăng nhập thành công.');
      isChecked = true;
    } else {
      console.log('Mật khẩu không chính xác.');
      isChecked = false;
    }
  } catch (error) {
    console.error('Lỗi kết nối hoặc truy vấn:', error);
  }
}

app.post('/users', async (req, res) => {
  console.log('log in');

  try {
    const { email, displayName, phoneNumber, city, age, code, apiRead, apiWrite } = req.body;
    const existingUser = await User.findOne({ email: email });

    if (!existingUser) {
      await insert(email, displayName, phoneNumber, city, age, code, apiRead, apiWrite);
      console.log('Insert');
    }
    console.log('log in thành công');
    res.status(200).json({ message: 'User processed successfully' });
  } catch (error) {
    console.error('Error processing user:', error);
    res.status(500).json({ message: 'Error processing user', error });
  }
});

app.post('/getDataWithEmail', async (req, res) => {
  const email = req.body.email;
  try {
    const existingUser = await User.findOne({ email: email });
    console.log(existingUser);
    if (existingUser) {
      res.json(existingUser);
    }
  } catch (err) {
    res.status(500).send({ message: 'Error retrieving data' });
  }
});

app.post('/getCity', async (req, res) => {
  const email = req.body.email;
  try {
    const existingUser = await User.findOne({ email: email });
    console.log(existingUser);
    if (existingUser) {
      res.json(existingUser.city);
    }
  } catch (err) {
    res.status(500).send({ message: 'Error retrieving data' });
  }
});

app.post('/updateData', async (req, res) => {
  try {
    const { email, displayName, phoneNumber, city, age } = req.body;
    const updatedUser = await User.findOneAndUpdate(
      { email: email },
      {
        displayName: displayName,
        age: age,
        city: city,
        phoneNumber: phoneNumber,
      },
      {
        new: true,
        upsert: true,
      }
    );

    if (updatedUser) {
      console.log('update');
    }
    res.status(200).json({ message: 'User processed successfully' });
  } catch (error) {
    console.error('Error processing user:', error);
    res.status(500).json({ message: 'Error processing user', error });
  }
});

// wss.on('connection', ws => {
//   console.log('Client connected');

//   ws.on('message', async message => {
//     console.log('Nhận từ client:', message);
//     try {
//       const data = JSON.parse(message);
//       const { email, password } = data;

//       await checkUser(email, password);

//       if (!isChecked) {
//         ws.send(JSON.stringify({ status: 'failed', message: 'Thông tin đăng nhập không hợp lệ' }));
//       } else {
//         const userLog = await User.findOne({ email: email });
//         ws.send(JSON.stringify({ status: 'success', userLog }));
//       }
//     } catch (error) {
//       console.error('Lỗi khi phân tích tin nhắn:', error);
//       ws.send(JSON.stringify({ status: 'error', message: 'Định dạng tin nhắn không hợp lệ' }));
//     }
//   });

//   ws.on('close', () => {
//     console.log('Khách hàng đã ngắt kết nối');
//   });
// });

// console.log('WebSocket server listening on ws://192.168.1.20:8080');

// Sử dụng IP và port khác cho HTTP server
http.listen(3000, '192.168.43.200', function () {
  console.log('Server running at http://192.168.1.20:3000');
});
