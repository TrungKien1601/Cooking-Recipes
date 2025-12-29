const mongoose = require('mongoose');

const connectDB = async () => {
    const uri = 'mongodb+srv://' + process.env.DB_USER + ':' + process.env.DB_PASS + '@' + process.env.DB_SERVER + '/' + process.env.DB_DATABASE;

    mongoose.connect(uri).then(() => {
        console.log('Connected to ' + process.env.DB_SERVER + '/' + process.env.DB_DATABASE);
    }).catch((err) => {
        console.error(err);
    });
};

module.exports = connectDB;