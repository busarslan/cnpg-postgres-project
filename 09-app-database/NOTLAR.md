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
