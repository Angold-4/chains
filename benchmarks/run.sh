#!/bin/bash

vegeta -cpus 10 attack -targets=vegeta/targets.txt -rate=80 -duration=80s | vegeta report                                                                                                                                                                                                                                                                                  
