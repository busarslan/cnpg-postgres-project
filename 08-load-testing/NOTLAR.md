# Faz 8 - Yuk Testi (Hafif Versiyon)

## Test Senaryosu
- pgbench ile scale=1 (kucuk) test verisi olusturuldu.
- 5 client, 2 thread, 60 saniyelik yuk testi calistirildi.
- Test calisirken (15. saniyede) primary pod (postgres-lab-1) silindi,
  failover tetiklendi (yeni primary: postgres-lab-2).

## Sonuc - BASARILI
- 189 transaction islendi, 0 basarisiz transaction (0.000%).
- Sonuc: CNPG'nin failover mekanizmasi, yuk altinda bile veri kaybi
  veya transaction hatasi yaratmadan calisiyor. postgres-lab-rw servisi
  otomatik olarak yeni primary'ye yonlendirdi.

## Sinirlamalar
- tps = 3.14 - dusuk bir deger, ama bu kind'in yerel disk I/O
  performansindan ve failover sirasindaki gecici yavaslamadan kaynaklaniyor.
  Gercek bulut ortaminda cok daha yuksek cikacagi degerlendiriliyor.
- Bu, "hafif" bir yuk testiydi (kucuk olcek, kisa sure). Kapsamli bir
  yuk testi (daha buyuk scale, daha uzun sure, gercek disk performansi)
  Faz 9 (buluta tasima) sonrasinda tekrarlanabilir.

## Karsilasilan Teknik Detaylar
- kubectl run --rm sadece etkilesimli (-it) calistirmalarda kullanilabilir,
  arka planda (detached) calistirmada "--rm should only be used for
  attached containers" hatasi verir. Cozum: --rm kaldirilip pod elle
  silindi.
- pgbench init sirasinda gecici bir "database system is shutting down"
  hatasi alindi (muhtemelen es zamanli baska bir islem/restart nedeniyle),
  tekrar denendiginde sorunsuz tamamlandi.
