#!/usr/bin/env bash

snakemake -s full_pipeline_snakefile all \
  --configfile="configs/scDINO_full_pipeline.yaml" \
  --keep-incomplete \
  --drop-metadata \
  --cores 1 \
  --jobs 1 \
  -k \
  --latency-wait 45 \
