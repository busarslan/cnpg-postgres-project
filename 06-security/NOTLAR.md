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
