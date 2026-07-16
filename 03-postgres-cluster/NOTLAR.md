# Faz 3 - Ogrenilenler ve Testler

## PodDisruptionBudget (PDB)
- CNPG operatoru, cluster olusturulur olusturulmaz KENDI PDB'lerini otomatik yaratiyor:
  - postgres-lab (MIN AVAILABLE: 1) -> replikalar icin
  - postgres-lab-primary (MAX UNAVAILABLE: 0) -> primary'nin gonullu tahliyesini tamamen engeller
- Elle ek bir PDB tanimlamaya GEREK YOK. Ayni pod'lari hedefleyen ikinci bir PDB eklemek,
  "This pod has more than one PodDisruptionBudget" hatasina yol aciyor (eviction API cakismasi).
- spec.enablePDB: true varsayilan olarak acik.

## topologySpreadConstraints - Onemli Kisitlama
- whenUnsatisfiable: DoNotSchedule kurali cok kati: bir zone'un tek node'u
  cordoned/drain edildiginde, o zone'a ait instance "Pending" kalir, baska
  bir zone'a kacak yerlesmez (bu aslinda istenen davranis, dogru calisiyor).
- Bu durum sadece "zone basina 1 node" olan lab ortaminda belirgin. Production'da
  her zone'da birden fazla node oldugu icin bu sorun pratikte yasanmiyor.
- Drain testi: pg-lab-worker3 drain edildiginde postgres-lab-1 (replika, primary
  degil) sorunsuz tahliye edildi ve PDB tarafindan durdurulmadi. Primary
  (postgres-lab-2) o node'da olsaydi, postgres-lab-primary PDB'si tahliyeyi
  reddedecekti.

## enableSuperuserAccess: false
- Bu cluster'da postgres superuser ile dogrudan baglanti KAPALI.
- Onceki lab denemesinde kullandigimiz "psql -U postgres" yontemi burada
  calismayacak - uygulama kullanicisi (busarslan) ile dogru baglanti
  yontemini kurmamiz gerekiyor.
