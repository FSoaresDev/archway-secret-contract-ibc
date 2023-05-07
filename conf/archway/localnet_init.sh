#!/bin/sh

# this script instantiates localnet required genesis files

set -e

echo clearing $HOME/.archway
rm -rf $HOME/.archway
echo initting new chain
# init config files
archwayd init archwayd-id --chain-id arch-local
archwayd config output json

# create accounts
# LOCALCHAIN ACCOUNTS FOR TEST PURPOSES ONLY (NEVER USE FOR PRODUCTION)

# acc0: archway1akmvyvwxw6t7k8qe89j9tje4ax2dxnymrazwyz
echo "episode filter soldier glue decide hero upon movie above aim high mercy cat boil replace coyote country blue artwork gold fury orchard horn duty" | archwayd keys add acc0 --keyring-backend=test --recover
# acc1: archway1d2f0vxsqpqf8yrkhhsxz2hs0zhu7fr2ut0djw5
echo "toddler pelican again waste hurt assist ladder paper under meadow again panel salt quality virus rose artist artefact extend trouble hub exact amazing auction" | archwayd keys add acc1 --keyring-backend=test --recover
# acc2: archway122n59t8vqrq9srl0t4r7a64d4auc3342kt0ct7
echo "claw goddess reward section health tiny motor head wild old warm curious auto symbol spell physical busy dizzy sketch major tuna paddle scissors cushion" | archwayd keys add acc2 --keyring-backend=test --recover
# acc3: archway15fz5pjwqlhmxff40tmkuz4z5na6n3frsh9pn0m
echo "blur true best oblige skirt slab next castle flame sugar adapt riot blue echo amateur auction agent borrow steak nation canyon hobby senior game" | archwayd keys add acc3 --keyring-backend=test --recover

# relayer acc
rly_archway=archway1f4gjcw35zpju9nkkxrrcsmp3e7cxaevcjgnjug

# give the accounts some money
archwayd add-genesis-account $(archwayd keys show acc0 -a --keyring-backend=test) 1000000000000000uarch --keyring-backend=test
archwayd add-genesis-account $(archwayd keys show acc1 -a --keyring-backend=test) 1000000000000000uarch --keyring-backend=test
archwayd add-genesis-account $(archwayd keys show acc2 -a --keyring-backend=test) 1000000000000000uarch --keyring-backend=test
archwayd add-genesis-account $(archwayd keys show acc3 -a --keyring-backend=test) 1000000000000000uarch --keyring-backend=test
archwayd add-genesis-account $rly_archway 1000000000000000uarch --keyring-backend=test

# save configs for the daemon
archwayd gentx acc0 10000000uarch --chain-id arch-local --keyring-backend=test

# input genTx to the genesis file
archwayd collect-gentxs
# verify genesis file is fine
archwayd validate-genesis
echo changing network settings
cp /tmp/config.toml $HOME/.archway/config/config.toml
cp /tmp/app.toml $HOME/.archway/config/app.toml

sed -i 's/127.0.0.1/0.0.0.0/g' $HOME/.archway/config/config.toml
sed -i 's/stake/uarch/' ~/.archway/config/genesis.json

# echo test account address: "$addr"
# echo test account private key: "$(yes | archwayd keys export fd --unsafe --unarmored-hex --keyring-backend=test)"
# echo account for --from flag "fd"

echo starting network...
archwayd start

