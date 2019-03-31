/*
 * Copyright (c) 2019 Jacob Stauffer ALL RIGHTS RESERVED
 */

const fs = require('fs')
const path = require('path')

const regStructValues = ['Device Serial Number', 'Windows Product ID', 'Hardware Hash', 'Manufacturer name', 'Device model']
const dataDir = path.join(__dirname, 'data')
const dataFile = path.join(dataDir, 'hostregistration.log')
const errorFile = path.join(dataDir, 'hostregistration_error.log')
const finalCSV = path.join(dataDir, 'hostregistration_final.csv')

// create data directories and files
fs.existsSync(dataDir) || fs.mkdirSync(dataDir)
fs.existsSync(dataFile) || fs.open(dataFile, 'w', (err) => { if (err) throw err })
fs.existsSync(errorFile) || fs.open(errorFile, 'w', (err) => { if (err) throw err })
fs.existsSync(errorFile) || fs.writeFileSync(finalCSV, `Timestamp,${regStructValues.map(value => { return '"' + value + '"' })}\n`)

async function parseRegistration(hostregistration) {
  hostregistration['Timestamp'] = new Date().toISOString(Date.now())
  // throw an error if something is missing
  // regStructValues.map(value => {
  //   if (!hostregistration[value] || hostregistration[value] == '') {
  //     // log error
  //     fs.appendFileSync(errorFile, JSON.stringify(hostregistration) + ',\n', (err) => {
  //       if (err) throw err
  //     })
  //     throw `${value} does not exist, registration failed.`
  //   }
  // })

  // verify the host has not been entered already
  var exists = false
  fs.readFileSync(dataFile).toString().split('\n').map(line => {
    if (line != '') {
      if (hostregistration['Device Serial Number'] == JSON.parse(line)['Device Serial Number'])
        exists = true
    }
  })

  if (!exists) {
    // log successful registration
    fs.appendFileSync(dataFile, JSON.stringify(hostregistration) + '\n', (err) => {
      if (err) throw err
    })

    // create CSV entry for M$ Autopilot
    fs.appendFileSync(finalCSV, `"${hostregistration.Timestamp}",${regStructValues.map(value => { return hostregistration[value] })}\n`, (err) => {
      if (err) throw err
    })
    return { "result": "Registration success" }
  }
  else {
    return { "result": "Host already registered" }
  }
}

module.exports = {
  parseRegistration
}