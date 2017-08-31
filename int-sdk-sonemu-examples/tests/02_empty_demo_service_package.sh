#!/bin/bash
set -e
set -x

printheader "https://github.com/sonata-nfv/son-emu/wiki/Example-2"

SONEMU() {
    docker exec son-emu-int-sdk-pipeline "$@"
}

SONCLI() {
    docker exec son-cli-int-test "$@"
}


### Starting the topology
SONEMU screen -L -S sonemu -d -m sudo python /son-emu/src/emuvim/examples/sonata_y1_demo_topology_1.py
### Setup screen for immediate flusing
SONEMU screen -S sonemu -X logfile flush 0
### Wait for the cli to start
SONEMU W '^*** Starting CLI:' 60s
### Print nodes
SONEMU Cmd 'nodes'

SONCLI son-access --platform emu push --upload son-examples/service-projects/sonata-empty-service.son
SONCLI son-access --platform emu push --deploy latest

SONEMU son-emu-cli compute list
SONEMU sync # avoid text overlapping

SONEMU Cmd 'empty_vnf1 ifconfig && sync && echo -e "\\n... checked empty_vnf1"'
SONEMU W "^... checked empty_vnf1"
SONEMU Cmd 'empty_vnf2 ifconfig && sync && echo -e "\\n... checked empty_vnf2"'
SONEMU W "^... checked empty_vnf2"
### Warning: while executing the echo command, the name of a nvf is substituted by its ip
SONEMU Cmd 'empty_vnf1 ping -v -c 2 empty_vnf2 && sync && echo -e "\\n... checked ping between Empty_vnf1 and Empty_vnf2"'
SONEMU W "^... checked ping between Empty_vnf1 and Empty_vnf2"
SONEMU Cmd 'empty_vnf1 ping -v -c 2 200.0.0.2 && sync && echo -e "\\n... checked ping between Empty_vnf1 and 200.0.0.2"'
SONEMU W "^... checked ping between Empty_vnf1 and 200.0.0.2"
SONEMU Cmd 'empty_vnf2 ping -v -c 2 empty_vnf1 && sync && echo -e "\\n... checked ping between Empty_vnf2 and Empty_vnf1"'
SONEMU W "^... checked ping between Empty_vnf2 and Empty_vnf1"
SONEMU Cmd 'empty_vnf2 ping -v -c 2 200.0.0.1 && sync && echo -e "\\n... checked ping between Empty_vnf2 and 200.0.0.1"'
SONEMU W "^... checked ping between Empty_vnf2 and 200.0.0.1"

SONEMU Cmd 'quit'
SONEMU W "^*** Done"

printheader "(Result) OK for https://github.com/sonata-nfv/son-emu/wiki/Example-2"
SONEMU strings screenlog.0
