#!/bin/bash

kubectl ns os-ccs23-dev
c8-backup restore
kubectl ns -
