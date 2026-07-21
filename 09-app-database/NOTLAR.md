# Faz 9 - Uygulama Veritabani

## Yaklasim
- CNPG'nin declarative `Database` CRD'si kullanildi (superuser
  psql erisimi olmadan, GitOps'a uygun sekilde yeni veritabani
  olusturuldu).
- saha_operasyon veritabani, mevcut postgres-lab cluster'i icinde,
  busarslan kullanicisi owner olacak sekilde acildi.

## Sema Kaynagi
- ERD diyagramina (MINEMATION) sadik kalinarak
  olusturuldu 

## Tasarim Kararlari
- 19 tablo, bunlardan 6'si Ekipman'in alt tipi (ekskavator, hafriyat,
  el_aletleri, kepce, sensor, kirici) - table-per-type deseniyle,
  PK = FK (ekipman_id) paylasilan anahtar.
- 2 tablo Rapor'un alt tipi (personel_raporu, ekipman_raporu) -
  ayni desen, rapor_id paylasilan anahtar.
- sensor_verisi'nde iki ayri ekipman iliskisi (sensor_ekipman_id,
  hedef_ekipman_id) ayristirildi.
- vaka'daki polimorfik "raporlayan (sensor, personel)" iki opsiyonel
  FK olarak modellendi.
- ENUM alanlari VARCHAR birakildi.

## Kurulum - BASARILI
- kubectl exec -i ile PGPASSWORD ortam degiskeni kullanilarak
  schema.sql basariyla uygulandi (21 CREATE TABLE, 23 CREATE INDEX,
  hic hata olmadan).
- Not: kubectl exec -i ile stdin'den SQL dosyasi gonderilirken psql'in
  interaktif sifre sormasi CALISMIYOR (stdin zaten dosyaya yonlendirilmis
  oluyor) - PGPASSWORD ortam degiskeni ile bu sorun asildi.

## Iliskisel Butunluk Testi - BASARILI
- 2 personel, 1 ekipman + ekskavator alt tipi, 1 vardiya, 1 ekip
  kaydi eklendi.
- Ekipman + Ekskavator JOIN'i basariyla calisti - table-per-type
  alt tip deseni dogrulandi.
- Vardiya, ISG sorumlusu ve ekipmani dogru FK'lerle bagladi.
- Ekip JOIN sorgusu (ekip + personel + vardiya) anlamli, dogru
  sonuc uretti: "Ahmet Yilmaz, Sabah Vardiyasi'nda operator".
- Sonuc: Sema sadece tablo yapisi olarak degil, iliskisel butunluk
  (foreign key + join) acisindan da dogru calisiyor.

## PITR Testi - Gercek Uygulama Verisiyle - BASARILI
- Manuel backup alindi (saha-operasyon-backup-1).
- ekip tablosuna yeni bir kayit (isg_uzmani_sahada) eklendi, tam zaman
  damgasi alindi.
- Kayit DELETE ile kasitli silindi.
- recoveryTarget.targetTime ile postgres-restored-saha adinda yeni
  bir cluster'a restore edildi.
- Restore sirasinda gecici bir "leader election lost" / API server
  timeout hatasi yasandi (hem postgres-lab hem restore cluster'i
  etkiledi) - ama TUM POD'LAR "Running" durumda kaldi, PostgreSQL
  surecinin kendisi hic durmadi. ~30 saniye sonra operatör kendi
  kendini topladi, her iki cluster da "Cluster in healthy state"e
  dondu.
- Restore edilen cluster'da ekip tablosu kontrol edildi: SILINEN
  KAYIT (isg_uzmani_sahada) EKSIKSIZ GERI GELDI, foreign key'ler
  (personel_id, vardiya_id) dahil tutarliydi.
- Sonuc: PITR mekanizmasi, gercek, iliskisel, cok tablolu bir
  uygulama semasiyla basariyla dogrulandi.
- Test sonrasi postgres-restored-saha cluster'i temizlendi.
