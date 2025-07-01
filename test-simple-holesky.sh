#!/bin/bash

# Script simplificado para testar dashboards Holesky

echo "🔍 Teste Simples dos Dashboards Holesky"
echo "======================================"
echo

echo "📊 Status dos Serviços:"
echo "Geth Status:"
curl -s "http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22geth-holesky%22%7D" | jq -r '.data.result[0].value[1]' 2>/dev/null | sed 's/1/✅ UP/; s/0/❌ DOWN/'

echo "Lighthouse Status:"
curl -s "http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22lighthouse-holesky%22%7D" | jq -r '.data.result[0].value[1]' 2>/dev/null | sed 's/1/✅ UP/; s/0/❌ DOWN/'

echo
echo "📈 Métricas Principais do Geth:"
echo -n "Current Block Header: "
curl -s "http://localhost:9090/api/v1/query?query=chain_head_header" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A"

echo -n "Connected Peers: "
curl -s "http://localhost:9090/api/v1/query?query=p2p_peers" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A"

echo
echo "📈 Métricas Principais do Lighthouse:"
echo -n "Service UP: "
curl -s "http://localhost:9090/api/v1/query?query=up%7Bjob%3D%22lighthouse-holesky%22%7D" | jq -r '.data.result[0].value[1]' 2>/dev/null | sed 's/1/✅ YES/; s/0/❌ NO/' || echo "N/A"

echo
echo "🔗 Dashboards disponíveis:"
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "Prometheus: http://localhost:9090"
echo
echo "📊 Dashboards refatorados:"
echo "• Geth Holesky Testnet Monitoring - com status UP/DOWN"
echo "• Lighthouse Holesky Testnet Monitoring - com status UP/DOWN"
echo "• Ambos seguem o padrão dos dashboards principais"
