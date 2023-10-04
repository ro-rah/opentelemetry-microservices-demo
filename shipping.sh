#!/usr/bin/env bash

# add vx to debug
set -euo pipefail
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

log() { echo "$1" >&2; }


TAG="${TAG:?TAG env variable must be specified}"
networkName=online-boutique
otelCollectorName=otelcollector
otelCollector="http://$otelCollectorName:4317"

cd src/shippingservice
# Get Sealights Agent
echo "[Sealights] Downloading Sealights Golang & CLI Agents..."
wget -nv -O sealights-go-agent.tar.gz https://agents.sealights.co/slgoagent/latest/slgoagent-linux-amd64.tar.gz
wget -nv -O sealights-slcli.tar.gz https://agents.sealights.co/slcli/latest/slcli-linux-amd64.tar.gz
tar -xzf ./sealights-go-agent.tar.gz && tar -xzf ./sealights-slcli.tar.gz 
rm -f ./sealights-go-agent.tar.gz ./sealights-slcli.tar.gz 
./slgoagent -v 2> /dev/null | grep version && ./slcli -v 2> /dev/null | grep version

echo "[Pipeline] Initializing agent and Generating a session ID"
echo 'eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL1BST0QtQ1VTVE9NRVJTMi5hdXRoLnNlYWxpZ2h0cy5pby8iLCJqd3RpZCI6IlBST0QtQ1VTVE9NRVJTMixpLTA3NGFjY2M3MDBiOWQ2MDg1LEFQSUdXLTU1ODNlOTlmLTgwNTItNGZiYi1iZmIxLTVmYjNlODNlM2Y4MiwxNjAzMjYzODMzMzcxIiwic3ViamVjdCI6ImNzZGVtb0BhZ2VudCIsImF1ZGllbmNlIjpbImFnZW50cyJdLCJ4LXNsLXJvbGUiOiJhZ2VudCIsIngtc2wtc2VydmVyIjoiaHR0cHM6Ly9QUk9ELUNVU1RPTUVSUzItZ3cuc2VhbGlnaHRzLmNvL2FwaSIsInNsX2ltcGVyX3N1YmplY3QiOiIiLCJpYXQiOjE2MDMyNjM4MzN9.auEaGEQyMW6VDSSX3sKXuRLSw_xeirj7g1g4fRwmCm3xSPYcgCWyHO-CN23s0f0svabb9qm2pJsDWr38YPq87WCWS-IuseHOVhn55VVGvnc4e5jJkXpUmQmjLTs8tFOoPsxHQsqCLYV-v0IdMyLMAJfbZ1qFlPgqf7rEYjBFkL55n4wJ1evDEAnMZcMeA-JVmHiEUO4xvUBiKqA-jT9yjdbwQcLSjfn9M2bJPe1bn5NyyAZsgZsopFlRiF_KH310tX3D7qtBnvN6Z9KuPrBcPnYbP_DLVG8G0MENXEr9wplh9CJHQOlvTyZZYv1JuwpnQWg4fxL8OKhn-cStpbike5Dl1xeR3O1trJ-BFNU-FzqLBj4zRSsJigeCO0p1AFeYx6Oo6Zucpf4NKLA8f-_Cj_eUqySRdrelLhUH1BfgtlazBoCYeZqCOyqi-K9jbyHVAVwyw3EYgGhOFwEcnciAHoqbxCIlvJ70t7nuPJMV7SjH7dGQnM0a2P4PjJ_Yg-AYQUVQaCI1Fa8LP8NU9AGXYjiewaS_pPKLQH8GiRvkxYX-4wfaF4onkuQr4MREntG8ppQvir5GCZ_3uLQQAklf1Ab9JnnMQP3kVL3Wz-58_ry4OocDKNHwL9n0ub-d83dcILeXtN9SSizw17SinIZpk8Gm1yz5NYjkzxLLd0wNMB4' > sltoken.txt
./slcli config init --lang go --token ./sltoken.txt
./slcli config create-bsid --app $APP_NAME --branch $BRANCH_NAME --build $BUILD_NAME
echo "[Sealights] Scan and Instrument code ..."
#try disable init w/o any args;then move arg position, check to see is scmProvider is dropped; then bug
pwd
./slcli scan --bsid buildSessionId.txt --path-to-scanner ./slgoagent --workspacepath ../../ --scm git --scmVersion "0" --scmProvider github --disable-on-init true

log "Successfully built shipping svc."