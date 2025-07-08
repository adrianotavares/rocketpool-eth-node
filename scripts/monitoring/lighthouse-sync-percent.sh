#!/bin/bash

# Script: lighthouse-sync-percent.sh
# Calcula o percentual de sincronização do Lighthouse

output=$(curl -s http://localhost:5052/eth/v1/node/syncing)
head_slot=$(echo "$output" | jq -r '.data.head_slot')
sync_distance=$(echo "$output" | jq -r '.data.sync_distance')

if [[ -z "$head_slot" || -z "$sync_distance" || "$head_slot" == "null" || "$sync_distance" == "null" ]]; then
  echo "Erro ao obter dados do Lighthouse. Endpoint não está acessível."
  exit 1
fi

total_slots=$((head_slot + sync_distance))
if [[ "$total_slots" -eq 0 ]]; then
  echo "Total de slots é zero. Não é possível calcular."
  exit 1
fi

percent_synced=$(awk "BEGIN { printf \"%.2f\", ($head_slot/$total_slots)*100 }")
percent_left=$(awk "BEGIN { printf \"%.2f\", ($sync_distance/$total_slots)*100 }")

echo "Head slot: $head_slot Sync distance: $sync_distance Total slots: $total_slots Sincronizado: $percent_synced% Falta: $percent_left%"