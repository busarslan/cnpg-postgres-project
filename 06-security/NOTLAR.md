# Faz 6 - Guvenlik Sikilastirmasi

## TLS Zorunlulugu - BASARILI
- CNPG varsayilan olarak zaten TLS aktif ediyordu (SHOW ssl -> on).
- pg_hba kurallari sikilastirildi: hostssl + hostnossl reject.
- Dogrulama yontemi degisti: busarslan superuser olmadigi icin
  pg_hba_file_rules view'ina erisemiyor ("permission denied for view").
  Bunun yerine DAVRANIS testi yapildi:
  - sslmode=disable -> FATAL: pg_hba.conf rejects connection (no encryption)
  - sslmode=require -> basarili baglanti
- Sonuc: TLS'siz baglanti KESIN olarak reddediliyor, TLS'li baglanti
  sorunsuz calisiyor.

## NetworkPolicy - BASARILI
- default-deny-all: database namespace'inde varsayilan olarak tum ingress
  trafigi reddediliyor.
- allow-postgres-access: sadece monitoring namespace'inden (port 9187,
  Prometheus scrape) ve database namespace'i icinden (port 5432,
  replikasyon + uygulama baglantisi) gelen trafige izin veriliyor.
- Test 1: default namespace'inden postgres-lab-rw servisine baglanti
  denemesi TIMEOUT ile sonuclandi (ag seviyesinde tamamen engellendi,
  sifre bile sorulmadi).
- Test 2: Prometheus monitoring hala calisiyor - targets sayfasinda UP.
- Sonuc: NetworkPolicy, TLS + dogru kimlik bilgisi olsa bile izin
  verilmeyen namespace'lerden gelen paketleri PostgreSQL'e ulasmadan
  engelliyor - defense in depth katmani basariyla calisiyor.

## Sealed Secrets - BASARILI
- sealed-secrets-controller kuruldu (kube-system namespace).
- kubeseal CLI kuruldu (v0.31.0).
- postgres-credentials ve minio-creds secret'lari SealedSecret formatina
  cevrildi (asimetrik sifreleme, sadece controller'in ozel anahtari
  cozebilir).
- Sealed halleri artik GUVENLE Git'e commit edilebilir - orijinal secret,
  yaml.example dosyalari yerine artik gercek sealed-secrets/*.yaml
  dosyalari kullanilabilir.
- Onemli: SealedSecret sadece OLUSTURULDUGU cluster'da (ayni controller
  anahtariyla) cozulebilir. Cluster yeniden kurulursa (bkz. KURTARMA-
  NOTLARI.md), sealed-secrets-controller'in KENDI anahtari da degisir,
  eski sealed dosyalari yeni cluster'da GECERSIZ olur - yeniden
  sealanmalari gerekir. Bu nedenle orijinal .example dosyalari da
  referans icin saklanmaya devam ediyor.

## Sifre Degisikligi Sonrasi Yasanan Sorun

### 1. Sealed Secrets Controller Eksikti
- Onceki bir cluster yeniden kurulumunda sealed-secrets-controller
  tekrar kurulmamisti.
- Cozum: kubectl apply ile controller.yaml tekrar kuruldu.
- NOT: Yeni controller kuruldugunda yeni bir sifreleme anahtari
  uretilir - eski sealed dosyalarin hicbiri artik gecerli olmuyor,
  hepsinin yeniden "sealed" edilmesi gerekiyor.

### 2. SealedSecret, Elle Olusturulmus Secret'i Guncelleyemedi
- Hata: "Resource minio-creds already exists and is not managed by
  SealedSecret"
- Kok sebep: minio-creds secret'i daha once kubectl create secret ile
  elle olusturulmustu (Faz 4'te). SealedSecrets, sahipligini kendisinde
  gormedigi bir Secret'i güvenlik geregi guncelleyemiyor (birinin
  rastgele bir SealedSecret ile baskasinin Secret'ini ele gecirmesini
  onlemek icin).
- Cozum: kubectl delete secret minio-creds -n database ile eski Secret
  silindi, SealedSecret controller'i onu kendi yonetiminde sifirdan
  yeniden olusturdu.
- ONEMLI DERS: Bir Secret'i SealedSecrets'a devretmek istiyorsan,
  once elle olusturulani silmen, sonra SealedSecret'in olusturmasina
  izin vermen gerekiyor.

### 3. postgres-lab-1 Kisir Donguye Girdi
- Sifre/secret degisikligi + controller restart'lari sirasinda
  postgres-lab-1, WAL/history dosyasini arsivden restore etmeye
  calisirken (restored log file "00000002.history" from archive)
  liveness/readiness probe'lari surekli timeout aldi (API server
  gecici yavasligi yuzunden), bu da container'in surekli oldurulup
  yeniden baslatilmasina, kurtarma surecinin hic tamamlanamamasina
  yol acti.
- Cozum: kubectl delete pod postgres-lab-1 -n database ile pod
  sifirdan yeniden olusturuldu, bu sefer sorunsuz senkronize oldu.
- Bu, primary olmayan bir instance'da yasandigi icin HA'yi tehlikeye
  atmadi (postgres-lab-2 primary olarak saglikli kaldi).

### Sifre Degisikligi - BASARIYLA TAMAMLANDI
- PostgreSQL busarslan kullanicisinin sifresi ALTER ROLE ile
  degistirildi.
- MinIO root sifresi de degistirildi, minio.yaml, sealed secret'lar
  ve dogrudan Secret'lar tum zincirde tutarli hale getirildi.
- Sonuc: ContinuousArchiving: True, Cluster in healthy state (3/3),
  guvenlik acigi Git'ten temizlendi.
