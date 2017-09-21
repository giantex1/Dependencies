#!/bin/bash

mkdir -p "${SRCROOT}/../build"
which pact-mock-service

pact-mock-service start --pact-specification-version 2.0.0 --log "${SRCROOT}/../build/pact.log" --pact-dir "${SRCROOT}/../build/pacts" -p 1234
