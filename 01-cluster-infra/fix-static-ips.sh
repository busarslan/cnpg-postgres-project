#!/bin/bash
# ============================================================
# kind Cluster - Statik IP Sabitleme Betigi
#
# SORUN: kind'in kullandigi ozel Docker agi (kind network),
# container'lara dinamik IP atiyor. Her "docker stop/start"
# dongusunde node'lar farkli bir IP alabiliyor. etcd'nin peer
# sertifikalari ise cluster ilk kuruldugu andaki IP'lere sabit
# oldugu icin, IP degisince "remote error: tls: bad certificate"
# hatasiyla etcd quorum kurulamiyor, kube-apiserver surekli
# crash-loop yasiyor.
#
# COZUM: Her node'un o anki IP'sini Docker agina KALICI olarak
# sabitlemek (docker network disconnect + connect --ip).
#
# KULLANIM: Cluster'i "kind create cluster" ile YENIDEN
# OLUSTURDUKTAN HEMEN SONRA, bir kez calistirilmali. Node'lar
# ilk olusumdaki IP'lerini alir, bu betik onlari sabitler.
# Sonraki tum docker stop/start dongulerinde bu IP'ler korunur.
#
# NOT: Eger "kind create cluster" ile SIFIRDAN yeni bir cluster
# olusturulursa, node'lar YENI/farkli IP'ler alabilir - bu
# durumda asagidaki IP degerlerini guncel IP'lerle degistirip
# tekrar calistirmak gerekir. Guncel IP'leri gormek icin:
#   docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
#     pg-lab-control-plane pg-lab-control-plane2 pg-lab-control-plane3 \
#     pg-lab-worker pg-lab-worker2 pg-lab-worker3
# ============================================================

set -e

echo "Worker node'larin IP'leri sabitleniyor..."
docker network disconnect kind pg-lab-worker
docker network connect --ip 172.18.0.3 kind pg-lab-worker

docker network disconnect kind pg-lab-worker2
docker network connect --ip 172.18.0.4 kind pg-lab-worker2

docker network disconnect kind pg-lab-worker3
docker network connect --ip 172.18.0.5 kind pg-lab-worker3

echo "Control-plane node'larin IP'leri sabitleniyor (tek tek, quorum'u korumak icin)..."

docker network disconnect kind pg-lab-control-plane
docker network connect --ip 172.18.0.7 kind pg-lab-control-plane
sleep 15

docker network disconnect kind pg-lab-control-plane2
docker network connect --ip 172.18.0.6 kind pg-lab-control-plane2
sleep 15

docker network disconnect kind pg-lab-control-plane3
docker network connect --ip 172.18.0.8 kind pg-lab-control-plane3
sleep 15

echo "Tamamlandi. Dogrulama:"
kubectl get nodes
