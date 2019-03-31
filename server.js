/*
 * Copyright (c) 2019 Jacob Stauffer ALL RIGHTS RESERVED
 */

// external requirements
const bodyParser = require('body-parser');
const express = require('express')
const expressWinston = require('express-winston')
const fs = require('fs')
const path = require('path')
const winston = require('winston')

// program parameters
const app = express()
const port = 8000
const logdir = path.join(__dirname, 'log')
const package = require('./package.json')

// setup error handling and body parser
app.use(require('./errorHandler'))
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

// create access logging
fs.existsSync(logdir) || fs.mkdirSync(logdir)
app.use(expressWinston.logger({
  transports: [
    new winston.transports.File({
      level: 'info',
      format: winston.format.combine(winston.format.json()),
      handleExceptions: true,
      filename: path.join(logdir, 'combined.log')
    })
  ]
}))

// setup API routes
app.use("/", require('./routes'))

// create error logging
app.use(expressWinston.errorLogger({
  dumpExceptions: true,
  showStack: true,
  transports: [
    new winston.transports.File({
      level: 'info',
      format: winston.format.combine(winston.format.json()),
      handleExceptions: true,
      filename: path.join(logdir, 'error.log')
    })
  ]
}))

// start server
app.listen(port, () => {
  console.log(`Program:\t${package.name}`)
  console.log(`Version:\t${package.version}`)
  console.log(`Author:\t\t${package.author}`)
  console.log(`Access Log:\t${path.join(logdir, 'combined.log')}`)
  console.log(`Error Log:\t${path.join(logdir, 'error.log')}`)
  console.log(`\n-----------------------------------------`)
  console.log(`Starting server --> listening on port ${port}`)
})
