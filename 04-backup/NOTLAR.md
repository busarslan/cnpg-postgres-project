# Faz 4 - MinIO Kalicilik Duzeltmesi

## emptyDir -> PersistentVolumeClaim
- Onceki lab denemesinde MinIO emptyDir kullaniyordu; pod yeniden olusunca
  TUM backup'lar kayboluyordu.
- Bu sefer minio-data adinda 5Gi'lik gercek bir PVC olusturuldu, MinIO
  deployment'i bu PVC'yi kullanacak sekilde guncellendi.

## Kalicilik Testi - BASARILI
- postgres-backups bucket'i olusturuldu.
- MinIO pod'u kasitli olarak silindi (kubectl delete pod).
- Pod yeniden olustu (farkli pod adiyla: ...-h7k6z -> ...-dbk9m).
- Bucket HALA MEVCUTTU (mc ls local ile dogrulandi).
- Sonuc: Verinin PVC'de, pod'un kendisinden bagimsiz olarak kalici oldugu
  kanitlandi.

## Kucuk Hata Notu
- YAML'da "accessModes: -ReadWriteOnce" yazildiginda (tireden sonra bosluk
  olmadan), YAML bunu liste degil string olarak yorumluyor ve hata veriyor.
  Dogrusu: "- ReadWriteOnce" (tire + bosluk + deger).

## ObjectStore + Cluster Entegrasyonu - BASARILI
- minio-creds secret'i olusturuldu (database namespace).
- ObjectStore CR'i (minio-store) tanimlandi.
- Cluster'a spec.plugins ile barman-cloud.cloudnative-pg.io eklendi,
  retentionPolicy: "7d" ayarlandi.
- Bu degisiklik rolling restart tetikledi: once replikalar (postgres-lab-3,
  postgres-lab-2), en son primary (postgres-lab-1) yeniden baslatildi.
- ContinuousArchiving condition'i True donuyor - WAL arsivleme calisiyor.
