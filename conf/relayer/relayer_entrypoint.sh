#!/bin/sh
sleep 15

hermes keys add --chain arch-local --key-file /root/.hermes/rly-archway.json
hermes keys add --chain secret-local --hd-path "m/44'/529'/0'/0/0" --mnemonic-file /root/.hermes/rly-secret.mnemonic --key-name rly-secret

sleep 30

#secret to archway channel
hermes create channel --a-chain secret-local --b-chain arch-local --a-port transfer --b-port transfer --new-client-connection --yes

hermes start