# succinct-prover
Guides Run Succinct Prover Spn-Node CPU with Docker


## Manual Calibrate

```
docker run --rm public.ecr.aws/succinct-labs/spn-node:latest-cpu calibrate \
    --usd-cost-per-hour 0.80 \
    --utilization-rate 0.5 \
    --profit-margin 0.1 \
    --prove-price 1.00
```