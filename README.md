# Guide Succinct Prover on Docker for CPU

Guides Run Succinct Prover Spn-Node CPU with Docker

# Full guide detail soon...

- Goto here create your on Prover https://staking.sepolia.succinct.xyz/prover
- Or staking with me boosting one https://staking.sepolia.succinct.xyz/?prover=0x43c1521281c6d7ea18d39ab033f5d99acdd90a40

## Cloning repo

```
git clone https://github.com/arcxteam/succinct-prover.git
cd succinct-prover
```

## Installing setup Docker and depedency
```
curl -sSL https://raw.githubusercontent.com/arcxteam/succinct-prover/refs/heads/main/docker.sh | sudo bash
```

## Build docker run
```
docker compose up -d
```

## Calibrate Prover

```
docker run --rm public.ecr.aws/succinct-labs/spn-node:latest-cpu calibrate \
    --usd-cost-per-hour 0.80 \
    --utilization-rate 0.5 \
    --profit-margin 0.1 \
    --prove-price 1.00
```

```diff
+ Calibration Results:
- Waiting for 10-15 Minutes, if you need fastest build on AVX256-512
┌──────────────────────┬─────────────────────────┐
│ Metric               │ Value                   │
├──────────────────────┼─────────────────────────┤
│ Estimated Throughput │ 25732 PGUs/second       │
├──────────────────────┼─────────────────────────┤
│ Estimated Bid Price  │ 3.27 $PROVE per 1B PGUs │
└──────────────────────┴─────────────────────────┘
```

## Setup your calibrate & run prover
```
nano .env
# input the valuable and then CTRL+X+Y
```

- PRIVATE_KEY= `add your private key wallet`
- PROVER_ADDRESS= `add your prover address`
- PGUS_PER_SECOND= `add value Estimated Throughput from calibrate`
- PROVE_PER_BPGU= `add value Estimated Bid Price from calibrate`

```
docker compose down
docker compose up -d
docker compose logs -f
# or docker logs -f succinct-prover
# or docker logs -f --tail=100
```
<img width="1435" height="539" alt="image" src="https://github.com/user-attachments/assets/f7784fe6-9dc8-4e86-a2fb-677f42ec7588" />
