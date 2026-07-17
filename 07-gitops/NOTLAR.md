# Faz 7 - GitOps (ArgoCD)

## Kurulum
- Repo GitHub'a tasindi (private): https://github.com/busarslan/cnpg-postgres-project
- ArgoCD kuruldu (kubectl apply, standart install.yaml).
- Ilk denemede buyuk CRD (ApplicationSet) "annotation too long" hatasi
  verdi -> --server-side --force-conflicts ile cozuldu (ilk seferinde
  etcd timeout yasandi ama pod'lar kendiliginden Running'e gecti).

## Ilk Application - postgres-lab-monitoring
- source.path: 05-monitoring
- destination.namespace: monitoring
- syncPolicy.automated: prune=false, selfHeal=true

## Karsilasilan Sorunlar ve Cozumleri
1. Private repo erisimi: GitHub Personal Access Token ile bir "repository"
   turunde Secret olusturuldu (argocd.argoproj.io/secret-type: repository
   etiketiyle).
2. cnpg-dashboard.json parse hatasi: ArgoCD, path altindaki her JSON/YAML
   dosyasini Kubernetes manifest'i sanip parse etmeye calisiyor. Dashboard
   dosyasi dashboards/ alt klasorune tasinarak cozuldu.
3. RBAC eksikligi: argocd-application-controller service account'u,
   monitoring.coreos.com API grubuna (PodMonitor, PrometheusRule)
   erisemiyordu. Ozel ClusterRole + ClusterRoleBinding eklenerek
   kalici cozuldu.
4. Yanlislikla kubeseal binary dosyalari (53MB) repoya commit edilmisti -
   .gitignore'a eklenerek temizlendi (repo GECMISINDE hala duruyor,
   gelecekte git filter-repo ile temizlenebilir).

## Kaynak Sinirlamasi Gozlemi (Onemli)
- Bugun boyunca tekrarlayan etcd/API server timeout'lari yasandi
  (TLS handshake timeout, etcdserver: request timed out, RBAC
  gecici tutarsizliklari).
- Kok sebep: 6 node HA cluster + CNPG + tam Prometheus stack + ArgoCD
  ayni anda laptop uzerinde calisiyor - kaynak baskisi.
- Sonuc: Komutlar bazen ilk denemede basarisiz oldu ama kisa bir bekleme
  (15-30 saniye) sonrasi tekrar denendiginde basarili oldu. Cluster
  gercek anlamda cokmedi, sadece gecici olarak yavasladi.
- Bu, buluta tasima (Faz 9) icin guclu bir motivasyon: gercek bulut
  kaynaklari bu sinirlamayi ortadan kaldiracak.

## GitOps Kaniti - BASARILI
- prometheusrule-custom.yaml icindeki "for: 1m" degeri "for: 2m" olarak
  degistirildi, commit edilip push edildi.
- HICBIR kubectl apply calistirilmadan, ArgoCD degisikligi otomatik
  olarak algiladi ve cluster'a uyguladi (polling ile, ~30-60 saniye
  icinde).
- Dogrulama: kubectl get prometheusrule ... -o jsonpath='...for' -> "2m"
