
## Gmail SMTP Entegrasyonu - BASARILI (Bir Sorun Sonrasi)
- Ilk denemede alarm Alertmanager'a ulasti (dogrulandi) ama e-posta gelmedi.
- Kok sebep: kube-prometheus-stack'in varsayilan config'inde "Watchdog" alarmi
  icin "null" adinda bir receiver kullaniliyor. Bizim --reuse-values ile
  gonderdigimiz custom config, receivers listesine sadece "gmail-notifications"
  ekledi, "null" receiver'ini SILDI (uzerine yazdi). Sonuc: Alertmanager
  config'i "undefined receiver null used in route" hatasiyla reddetti,
  RECONCILED: False durumuna dustu - SMTP hic calismadi, sessizce.
- Teshis: `kubectl describe alertmanager` ile Status.Conditions bolumunde
  tam hata mesaji bulundu.
- Cozum: alertmanager-values.yaml'a `- name: 'null'` (bos receiver) eklendi.
- Sonuc: RECONCILED: True, gercek bir test alarmi Gmail'e basariyla ulasti.
- ONEMLI DERS: kube-prometheus-stack gibi hazir chart'larin varsayilan
  config'lerini "reuse-values" ile ozellestirirken, chart'in kendi ic
  bagimliliklarini (bu ornekte "null" receiver) yanlislikla silmemek gerekir.
