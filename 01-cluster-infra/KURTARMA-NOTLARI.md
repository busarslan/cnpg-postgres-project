# Cluster Cokmesi ve Kurtarma - 2026-07-17

## Sorun
Bilgisayar kapatilip acildiktan sonra kind cluster'i bozuldu:
- kube-apiserver surekli crash loop yasadi (ATTEMPT: 8+)
- etcd de birkac kez yeniden basladi
- `kubectl get nodes` "connection refused" / "EOF" hatalari verdi

## Kok Sebep (Tahmin Edilen)
Bilgisayarin ani kapatilmasi + acilista sistem saatinin "siçramasi",
etcd'nin ic tutarliligini bozmus olabilir (Raft konsensus saat
hassasiyetine dayanir). kind, uzun sureli "duraklat-devam et" senaryolari
icin degil, kisa omurlu CI/CD test ortamlari icin tasarlanmis - bu tur
kirilmalar bilinen bir risktir.

## Cozum (Uygulanan)
Cluster'i debug etmeye calismak yerine (crictl loglarindan net bir sonuc
alinamadi) DOGRUDAN YENIDEN OLUSTURULDU:

```bash
kind delete cluster --name pg-lab
cd ~/cnpg-postgres-project/01-cluster-infra
kind create cluster --name pg-lab --config kind-config.yaml
```

Sonra TUM altyapi Git'teki dosyalardan sirayla yeniden kuruldu (yaklasik
20-30 dakika surdu, coglu adim sadece `kubectl apply -f <dosya>`):
1. Zone etiketleri (elle, 3 komut)
2. CNPG operatoru (helm install)
3. cert-manager + Barman Cloud Plugin
4. database namespace + secret.yaml + cluster.yaml
5. MinIO (PVC + Deployment + Service, elle - henuz ayri dosyaya alinmadi)
6. minio-creds secret + objectstore.yaml
7. Cluster'i plugine baglama (patch komutu)
8. scheduledbackup.yaml
9. kube-prometheus-stack (helm)
10. PodMonitor'ler + PrometheusRule'lar
11. alertmanager-values.yaml (ELLE yeniden yazildi - .gitignore'da oldugu
    icin Git'te yok, .example dosyasindan kopyalanmali)

## Yeniden Olusturma Sirasinda Cikan Yeni Hatalar
- prometheusrule-custom.yaml'da `\$` (gecersiz escape) -> `$` yapildi
- alertmanager-values.yaml'da "reciever" yazim hatasi -> "receiver" yapildi

## Onleyici Tedbir (Gelecek Icin)
Bilgisayari kapatmadan ONCE:
```bash
docker stop pg-lab-control-plane pg-lab-control-plane2 pg-lab-control-plane3 \
  pg-lab-worker pg-lab-worker2 pg-lab-worker3 pg-lab-external-load-balancer
```
Bu riski azaltir ama garanti etmez. Kalici cozum: Faz 9'da buluta tasima.

## Onemli Eksik
MinIO YAML'lari henuz ayri bir dosyaya kaydedilmedi (04-backup/minio.yaml
gibi), hala elle/inline yaziliyor. Bunu yapmak bir sonraki oncelik olmali.
