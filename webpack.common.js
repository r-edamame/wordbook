
const path = require('path');

module.exports = {
  entry: {
    "main": './src/index.js',
    "auth": './src/auth.js',
  },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name]_bundle.js'
  }
}

