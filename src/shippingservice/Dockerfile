# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


FROM golang:1.17.7-alpine as builder
ARG APP_NAME="changeme"
ARG BRANCH_NAME="changeme"
ARG BUILD_NAME="changeme"
ARG SEALIGHTS_TOKEN="changeme"
ARG SEALIGHTS_DISABLE="true"
RUN echo "$SEALIGHTS_TOKEN" >> ./sltoken.txt
RUN cat  ./sltoken.txt
RUN apk add --no-cache ca-certificates git
RUN apk add build-base
WORKDIR /src

# restore dependencies
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Get Sealights Agent
RUN echo "[Sealights] Downloading Sealights Golang & CLI Agents..."
RUN wget -nv -O sealights-go-agent.tar.gz https://agents.sealights.co/slgoagent/latest/slgoagent-linux-amd64.tar.gz
RUN wget -nv -O sealights-slcli.tar.gz https://agents.sealights.co/slcli/latest/slcli-linux-amd64.tar.gz
RUN tar -xzf ./sealights-go-agent.tar.gz && tar -xzf ./sealights-slcli.tar.gz 
RUN rm -f ./sealights-go-agent.tar.gz ./sealights-slcli.tar.gz 
RUN ./slgoagent -v 2> /dev/null | grep version && ./slcli -v 2> /dev/null | grep version

RUN echo "[Pipeline] Initializing agent and Generating a session ID"
RUN echo 'eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL1BST0QtQ1VTVE9NRVJTMi5hdXRoLnNlYWxpZ2h0cy5pby8iLCJqd3RpZCI6IlBST0QtQ1VTVE9NRVJTMixpLTA3NGFjY2M3MDBiOWQ2MDg1LEFQSUdXLTU1ODNlOTlmLTgwNTItNGZiYi1iZmIxLTVmYjNlODNlM2Y4MiwxNjAzMjYzODMzMzcxIiwic3ViamVjdCI6ImNzZGVtb0BhZ2VudCIsImF1ZGllbmNlIjpbImFnZW50cyJdLCJ4LXNsLXJvbGUiOiJhZ2VudCIsIngtc2wtc2VydmVyIjoiaHR0cHM6Ly9QUk9ELUNVU1RPTUVSUzItZ3cuc2VhbGlnaHRzLmNvL2FwaSIsInNsX2ltcGVyX3N1YmplY3QiOiIiLCJpYXQiOjE2MDMyNjM4MzN9.auEaGEQyMW6VDSSX3sKXuRLSw_xeirj7g1g4fRwmCm3xSPYcgCWyHO-CN23s0f0svabb9qm2pJsDWr38YPq87WCWS-IuseHOVhn55VVGvnc4e5jJkXpUmQmjLTs8tFOoPsxHQsqCLYV-v0IdMyLMAJfbZ1qFlPgqf7rEYjBFkL55n4wJ1evDEAnMZcMeA-JVmHiEUO4xvUBiKqA-jT9yjdbwQcLSjfn9M2bJPe1bn5NyyAZsgZsopFlRiF_KH310tX3D7qtBnvN6Z9KuPrBcPnYbP_DLVG8G0MENXEr9wplh9CJHQOlvTyZZYv1JuwpnQWg4fxL8OKhn-cStpbike5Dl1xeR3O1trJ-BFNU-FzqLBj4zRSsJigeCO0p1AFeYx6Oo6Zucpf4NKLA8f-_Cj_eUqySRdrelLhUH1BfgtlazBoCYeZqCOyqi-K9jbyHVAVwyw3EYgGhOFwEcnciAHoqbxCIlvJ70t7nuPJMV7SjH7dGQnM0a2P4PjJ_Yg-AYQUVQaCI1Fa8LP8NU9AGXYjiewaS_pPKLQH8GiRvkxYX-4wfaF4onkuQr4MREntG8ppQvir5GCZ_3uLQQAklf1Ab9JnnMQP3kVL3Wz-58_ry4OocDKNHwL9n0ub-d83dcILeXtN9SSizw17SinIZpk8Gm1yz5NYjkzxLLd0wNMB4' > sltoken.txt
RUN ./slcli config init --lang go --token ./sltoken.txt
RUN ./slcli config create-bsid --app $APP_NAME --branch $BRANCH_NAME --build $BUILD_NAME
RUN echo "[Sealights] Scan and Instrument code ..."
#try disable init w/o any args;then move arg position, check to see is scmProvider is dropped; then bug
RUN ./slcli scan --bsid buildSessionId.txt --path-to-scanner ./slgoagent --workspacepath ../../ --scm git --scmVersion "0" --scmProvider github --disable-on-init true

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS
RUN go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /go/bin/shippingservice .

FROM alpine as release
RUN apk add --no-cache ca-certificates
RUN GRPC_HEALTH_PROBE_VERSION=v0.4.7 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe
WORKDIR /src
COPY --from=builder /go/bin/shippingservice /src/shippingservice
ENV APP_PORT=50051

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single

#ENV SEALIGHTS_DISABLE_ON_INIT=false
ENV SEALIGHTS_DISABLE_ON_INIT=$SEALIGHTS_DISABLE

EXPOSE 50051
ENTRYPOINT ["/src/shippingservice"]
