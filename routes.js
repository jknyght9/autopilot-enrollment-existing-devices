/*
 * Copyright (c) 2019 Jacob Stauffer ALL RIGHTS RESERVED
 */

// external requirements
const express = require('express')
const router = express.Router()

// paramters
const apps = require('./autoPilotParserService')

// APIs
router.get('/', rootPath)
router.post('/register', registerHost)

// API functions
function rootPath(req, res, next) {
  res.status(200).send("Successfull connection.")
}

function registerHost(req, res, next) {
  apps
    .parseRegistration(req.body)
    .then(parsed => (parsed ? res.json(parsed) : res.sendStatus(404)))
    .catch(err => next(err))
}

module.exports = router