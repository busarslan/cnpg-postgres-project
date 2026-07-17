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
