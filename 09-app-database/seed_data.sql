-- ============================================================
-- SAHA OPERASYON - Sahte (Seed) Veri Uretim Betigi (DUZELTILMIS)
-- Hedef veritabani: saha_operasyon
--
-- ONEMLI DUZELTME NOTU: Ilk versiyonda "(SELECT x FROM tablo
-- ORDER BY random() LIMIT 1)" seklindeki iliskisiz alt sorgular,
-- PostgreSQL tarafindan SORGU BASINA BIR KEZ calistirilip tum
-- satirlarda ayni deger tekrar edildigi icin, FK'ler cesitlenmek
-- yerine hep ayni degere sabitleniyordu. Bu versiyonda CROSS JOIN
-- LATERAL kullanilarak her satir icin GERCEKTEN farkli bir rastgele
-- deger secilmesi saglandi. Ayrica kan_grubu degerleri kisa formata
-- (A+, A-, vb.) cevrilerek VARCHAR(5) sinir hatasi da giderildi.
--
-- BU BETIK, mevcut seed verisini (Adim 0'daki TRUNCATE ile) once
-- temizler, sonra tum tablolari sifirdan doldurur.
-- ============================================================

-- ============================================================
-- 0. TEMIZLIK: Onceki (hatali) seed verisini ve test verisini sil
-- ============================================================

TRUNCATE TABLE
    vaka_raporu, ekipman_raporu, personel_raporu, rapor,
    aksiyon, vaka, log_kaydi, sensor_verisi, takip_cihazi,
    ekip, vardiya,
    kirici, sensor, kepce, el_aletleri, hafriyat, ekskavator, ekipman,
    acil_durum_iletisim, saglik_bilgileri, personel
RESTART IDENTITY CASCADE;

-- ============================================================
-- 1. PERSONEL (50 kayit)
-- ============================================================

INSERT INTO personel (
    personel_ad, personel_soyad, uzmanlik, tckn, sifre_hash, durum,
    dogum_tarihi, cinsiyet, tel_no, ikinci_tel_no, eposta, adres,
    ise_giris_tarihi, calisan_tipi, calisabildigi_ekipman_turleri,
    rfid_kart_numarasi, kullanici_rolu, departman
)
SELECT
    (ARRAY['Ahmet','Mehmet','Mustafa','Ali','Huseyin','Ibrahim','Osman','Yusuf','Emre','Burak',
           'Fatma','Ayse','Zeynep','Elif','Hatice','Merve','Esra','Sultan','Betul','Gulsen'])[1+floor(random()*20)],
    (ARRAY['Yilmaz','Kaya','Demir','Sahin','Celik','Yildiz','Yildirim','Ozturk','Aydin','Ozdemir',
           'Arslan','Dogan','Kilic','Aslan','Cetin','Kurt','Ozkan','Simsek','Colak','Polat'])[1+floor(random()*20)],
    (ARRAY['Ekskavator Operatoru','Kamyon Soforu','Sensor Teknisyeni','ISG Uzmani','Saha Muhendisi',
           'Bakim Teknisyeni','Vardiya Amiri','Elektrik Teknisyeni','Jeoloji Muhendisi','Guvenlik Gorevlisi'])[1+floor(random()*10)],
    lpad((10000000000 + floor(random()*89999999999))::bigint::text, 11, '0'),
    md5(random()::text || i::text),
    (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['izinli','pasif'])[1+floor(random()*2)::int] END),
    (CURRENT_DATE - ((20*365) + floor(random()*(20*365)))::int),
    (ARRAY['erkek','kadin'])[1+floor(random()*2)],
    '05' || lpad(floor(random()*999999999)::text, 9, '0'),
    CASE WHEN random() > 0.5 THEN '05' || lpad(floor(random()*999999999)::text, 9, '0') ELSE NULL END,
    'personel' || i || '@sahaoperasyon.com',
    (ARRAY['Zonguldak','Ankara','Kayseri','Erzurum','Elazig','Diyarbakir'])[1+floor(random()*6)] || ' Sahasi, Bina ' || (1+floor(random()*10))::text,
    (CURRENT_DATE - floor(random()*3000)::int),
    (ARRAY['tam_zamanli','yari_zamanli','sozlesmeli'])[1+floor(random()*3)],
    (ARRAY['ekskavator,kamyon','hafriyat,kepce','el_aleti,kirici','sensor,takip_cihazi','tum_ekipmanlar'])[1+floor(random()*5)],
    'RFID-' || lpad(i::text, 6, '0'),
    (ARRAY['operator','isg_uzmani','teknisyen','muhendis','vardiya_amiri','yonetici'])[1+floor(random()*6)],
    (ARRAY['Saha Operasyonlari','Is Sagligi ve Guvenligi','Bakim ve Onarim','Lojistik','Teknik Ofis'])[1+floor(random()*5)]
FROM generate_series(1, 50) i;

-- ============================================================
-- 2. SAGLIK BILGILERI (tum personel icin)
-- ============================================================

INSERT INTO saglik_bilgileri (personel_id, kan_grubu, saglik_durumu, kronik_hastaliklar, alerjiler, saglik_calisma_kisitlamalari)
SELECT
    personel_id,
    (ARRAY['A+','A-','B+','B-','AB+','AB-','0+','0-'])[1+floor(random()*8)],
    (ARRAY['saglikli','gozlem_altinda','tedavi_goruyor'])[1+floor(random()*3)],
    CASE WHEN random() > 0.7 THEN (ARRAY['hipertansiyon','diyabet','astim','yok'])[1+floor(random()*4)] ELSE 'yok' END,
    CASE WHEN random() > 0.8 THEN (ARRAY['polen','toz','ilac_alerjisi','yok'])[1+floor(random()*4)] ELSE 'yok' END,
    CASE WHEN random() > 0.85 THEN 'agir_yuk_kaldirma_kisitlamasi' ELSE NULL END
FROM personel;

-- ============================================================
-- 3. ACIL DURUM ILETISIM (tum personel icin)
-- ============================================================

INSERT INTO acil_durum_iletisim (personel_id, acil_durum_kisileri_ad, acil_durum_kisileri_soyad, acil_durum_kisileri_yakinlik, acil_durum_kisileri_tel_no)
SELECT
    personel_id,
    (ARRAY['Ayse','Fatma','Mehmet','Ali','Zeynep'])[1+floor(random()*5)],
    personel_soyad,
    (ARRAY['es','anne','baba','kardes','cocuk'])[1+floor(random()*5)],
    '05' || lpad(floor(random()*999999999)::text, 9, '0')
FROM personel;

-- ============================================================
-- 4. EKIPMAN + ALT TIPLER (her tipten 15 adet, toplam 90)
-- ============================================================

-- --- Ekskavator ---
WITH yeni_ekipman AS (
    INSERT INTO ekipman (ekipman_adi, ekipman_marka, ekipman_model, durum, son_bakim_tarihi, gelecek_bakim_tarihi,
                          seri_no, rfid_etiketi, uretici_firma, tedarikci_firma, uretim_yili, boyut, agirlik,
                          satin_alma_tarihi, garanti_baslangic_tarihi, garanti_bitis_tarihi)
    SELECT
        'Ekskavator-' || lpad(i::text, 3, '0'),
        (ARRAY['Caterpillar','Komatsu','Hitachi','Volvo','Liebherr'])[1+floor(random()*5)],
        (ARRAY['320D','336','PC200','ZX210','EC220'])[1+floor(random()*5)],
        (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['bakimda','pasif'])[1+floor(random()*2)::int] END),
        (CURRENT_DATE - floor(random()*180)::int),
        (CURRENT_DATE + floor(random()*180)::int),
        'EKS-SN-' || lpad(i::text, 6, '0'),
        'RFIDEQ-' || lpad(i::text, 6, '0'),
        (ARRAY['Cat Turkiye','Komatsu Turkiye','Borusan Makine'])[1+floor(random()*3)],
        (ARRAY['ABC Tedarik','XYZ Makine','Saha Lojistik'])[1+floor(random()*3)],
        (2012 + floor(random()*13))::int,
        (ARRAY['buyuk','orta','kucuk'])[1+floor(random()*3)],
        (12 + random()*25)::numeric(12,2),
        (CURRENT_DATE - floor(random()*2000)::int),
        (CURRENT_DATE - floor(random()*1000)::int),
        (CURRENT_DATE + floor(random()*1000)::int)
    FROM generate_series(1, 15) i
    RETURNING ekipman_id
)
INSERT INTO ekskavator (ekipman_id, plaka, kova_kapasite, motor_gucu, maksimum_kazi_derinligi, palet_tipi, bom_uzunlugu)
SELECT
    ekipman_id,
    '34' || lpad(floor(random()*999)::text, 3, '0') || (ARRAY['ABC','DEF','GHI','JKL'])[1+floor(random()*4)],
    (0.8 + random()*1.5)::numeric(12,2),
    (100 + random()*150)::numeric(12,2),
    (4 + random()*3)::numeric(12,2),
    (ARRAY['celik','kaucuk'])[1+floor(random()*2)],
    (5 + random()*3)::numeric(12,2)
FROM yeni_ekipman;

-- --- Hafriyat ---
WITH yeni_ekipman AS (
    INSERT INTO ekipman (ekipman_adi, ekipman_marka, ekipman_model, durum, son_bakim_tarihi, gelecek_bakim_tarihi,
                          seri_no, rfid_etiketi, uretici_firma, tedarikci_firma, uretim_yili, boyut, agirlik,
                          satin_alma_tarihi, garanti_baslangic_tarihi, garanti_bitis_tarihi)
    SELECT
        'Hafriyat-' || lpad(i::text, 3, '0'),
        (ARRAY['Mercedes','MAN','Scania','Volvo','DAF'])[1+floor(random()*5)],
        (ARRAY['Actros','TGX','R500','FH16','XF'])[1+floor(random()*5)],
        (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['bakimda','pasif'])[1+floor(random()*2)::int] END),
        (CURRENT_DATE - floor(random()*180)::int),
        (CURRENT_DATE + floor(random()*180)::int),
        'HAF-SN-' || lpad(i::text, 6, '0'),
        'RFIDEQ-H' || lpad(i::text, 6, '0'),
        (ARRAY['Mercedes Turk','MAN Turkiye','Scania Turkiye'])[1+floor(random()*3)],
        (ARRAY['ABC Tedarik','XYZ Makine'])[1+floor(random()*2)],
        (2014 + floor(random()*11))::int,
        'buyuk',
        (15 + random()*20)::numeric(12,2),
        (CURRENT_DATE - floor(random()*2000)::int),
        (CURRENT_DATE - floor(random()*1000)::int),
        (CURRENT_DATE + floor(random()*1000)::int)
    FROM generate_series(1, 15) i
    RETURNING ekipman_id
)
INSERT INTO hafriyat (ekipman_id, plaka, damper_hacmi, azami_yuklu_agirlik, dingil_sayisi)
SELECT
    ekipman_id,
    '34' || lpad(floor(random()*999)::text, 3, '0') || (ARRAY['MNO','PQR','STU'])[1+floor(random()*3)],
    (10 + random()*15)::numeric(12,2),
    (20 + random()*15)::numeric(12,2),
    (2 + floor(random()*3))::int
FROM yeni_ekipman;

-- --- El Aletleri ---
WITH yeni_ekipman AS (
    INSERT INTO ekipman (ekipman_adi, ekipman_marka, ekipman_model, durum, son_bakim_tarihi, gelecek_bakim_tarihi,
                          seri_no, rfid_etiketi, uretici_firma, tedarikci_firma, uretim_yili, boyut, agirlik,
                          satin_alma_tarihi, garanti_baslangic_tarihi, garanti_bitis_tarihi)
    SELECT
        'El-Aleti-' || lpad(i::text, 3, '0'),
        (ARRAY['Bosch','Makita','DeWalt','Hilti','Milwaukee'])[1+floor(random()*5)],
        (ARRAY['GBH-5','HR2470','DCD996','TE-30','M18'])[1+floor(random()*5)],
        (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['bakimda','pasif'])[1+floor(random()*2)::int] END),
        (CURRENT_DATE - floor(random()*90)::int),
        (CURRENT_DATE + floor(random()*90)::int),
        'ELA-SN-' || lpad(i::text, 6, '0'),
        'RFIDEQ-E' || lpad(i::text, 6, '0'),
        (ARRAY['Bosch Turkiye','Makita Turkiye','Hilti Turkiye'])[1+floor(random()*3)],
        (ARRAY['ABC Tedarik','Yapi Market'])[1+floor(random()*2)],
        (2018 + floor(random()*7))::int,
        'kucuk',
        (2 + random()*8)::numeric(12,2),
        (CURRENT_DATE - floor(random()*1000)::int),
        (CURRENT_DATE - floor(random()*500)::int),
        (CURRENT_DATE + floor(random()*500)::int)
    FROM generate_series(1, 15) i
    RETURNING ekipman_id
)
INSERT INTO el_aletleri (ekipman_id, guc_kaynagi_tipi, batarya_kapasitesi, kullanim_amaci)
SELECT
    ekipman_id,
    (ARRAY['elektrikli','bataryali','hava_basincli'])[1+floor(random()*3)],
    (2 + random()*8)::numeric(12,2),
    (ARRAY['delme','kesme','sikma','tasima'])[1+floor(random()*4)]
FROM yeni_ekipman;

-- --- Kepce ---
WITH yeni_ekipman AS (
    INSERT INTO ekipman (ekipman_adi, ekipman_marka, ekipman_model, durum, son_bakim_tarihi, gelecek_bakim_tarihi,
                          seri_no, rfid_etiketi, uretici_firma, tedarikci_firma, uretim_yili, boyut, agirlik,
                          satin_alma_tarihi, garanti_baslangic_tarihi, garanti_bitis_tarihi)
    SELECT
        'Kepce-' || lpad(i::text, 3, '0'),
        (ARRAY['JCB','Case','New Holland','Terex','Volvo'])[1+floor(random()*5)],
        (ARRAY['3CX','580N','B95','TX760','L120'])[1+floor(random()*5)],
        (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['bakimda','pasif'])[1+floor(random()*2)::int] END),
        (CURRENT_DATE - floor(random()*180)::int),
        (CURRENT_DATE + floor(random()*180)::int),
        'KEP-SN-' || lpad(i::text, 6, '0'),
        'RFIDEQ-K' || lpad(i::text, 6, '0'),
        (ARRAY['JCB Turkiye','Case Turkiye'])[1+floor(random()*2)],
        (ARRAY['ABC Tedarik','XYZ Makine'])[1+floor(random()*2)],
        (2013 + floor(random()*12))::int,
        'orta',
        (8 + random()*10)::numeric(12,2),
        (CURRENT_DATE - floor(random()*2000)::int),
        (CURRENT_DATE - floor(random()*1000)::int),
        (CURRENT_DATE + floor(random()*1000)::int)
    FROM generate_series(1, 15) i
    RETURNING ekipman_id
)
INSERT INTO kepce (ekipman_id, plaka, yukleme_kapasitesi, kova_genisligi, bosaltma_yuksekligi, devrilme_yuku, saglik_calisma_kisitlamalari)
SELECT
    ekipman_id,
    '34' || lpad(floor(random()*999)::text, 3, '0') || (ARRAY['VWX','YZA'])[1+floor(random()*2)],
    (1.5 + random()*2)::numeric(12,2),
    (1 + random()*1.5)::numeric(12,2),
    (2.5 + random()*1.5)::numeric(12,2),
    (3 + random()*2)::numeric(12,2),
    NULL
FROM yeni_ekipman;

-- --- Sensor ---
WITH yeni_ekipman AS (
    INSERT INTO ekipman (ekipman_adi, ekipman_marka, ekipman_model, durum, son_bakim_tarihi, gelecek_bakim_tarihi,
                          seri_no, rfid_etiketi, uretici_firma, tedarikci_firma, uretim_yili, boyut, agirlik,
                          satin_alma_tarihi, garanti_baslangic_tarihi, garanti_bitis_tarihi)
    SELECT
        'Sensor-' || lpad(i::text, 3, '0'),
        (ARRAY['Siemens','Honeywell','ABB','Schneider','Endress+Hauser'])[1+floor(random()*5)],
        (ARRAY['SITRANS','ST3000','266','Vega','Promass'])[1+floor(random()*5)],
        (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['bakimda','pasif'])[1+floor(random()*2)::int] END),
        (CURRENT_DATE - floor(random()*90)::int),
        (CURRENT_DATE + floor(random()*90)::int),
        'SEN-SN-' || lpad(i::text, 6, '0'),
        'RFIDEQ-S' || lpad(i::text, 6, '0'),
        (ARRAY['Siemens Turkiye','ABB Turkiye'])[1+floor(random()*2)],
        (ARRAY['Endustriyel Otomasyon Ltd'])[1],
        (2019 + floor(random()*6))::int,
        'kucuk',
        (0.2 + random()*2)::numeric(12,2),
        (CURRENT_DATE - floor(random()*800)::int),
        (CURRENT_DATE - floor(random()*400)::int),
        (CURRENT_DATE + floor(random()*400)::int)
    FROM generate_series(1, 15) i
    RETURNING ekipman_id
)
INSERT INTO sensor (ekipman_id, sensor_tipi, hassasiyet, sensor_durumu, olcum_araligi_max, olcum_araligi_min, haberlesme_tipi, baglanti_protokolu)
SELECT
    ekipman_id,
    (ARRAY['titresim','sicaklik','basinc','gaz','nem'])[1+floor(random()*5)],
    (0.001 + random()*0.5)::numeric(12,4),
    (CASE WHEN random() < 0.9 THEN 'aktif' ELSE (ARRAY['kalibrasyon_bekliyor','ariza'])[1+floor(random()*2)::int] END),
    (100 + random()*900)::numeric(12,2),
    (0 + random()*10)::numeric(12,2),
    (ARRAY['kablosuz','kablolu'])[1+floor(random()*2)],
    (ARRAY['Modbus','MQTT','LoRaWAN','OPC-UA'])[1+floor(random()*4)]
FROM yeni_ekipman;

-- --- Kirici ---
WITH yeni_ekipman AS (
    INSERT INTO ekipman (ekipman_adi, ekipman_marka, ekipman_model, durum, son_bakim_tarihi, gelecek_bakim_tarihi,
                          seri_no, rfid_etiketi, uretici_firma, tedarikci_firma, uretim_yili, boyut, agirlik,
                          satin_alma_tarihi, garanti_baslangic_tarihi, garanti_bitis_tarihi)
    SELECT
        'Kirici-' || lpad(i::text, 3, '0'),
        (ARRAY['Atlas Copco','Furukawa','Rammer','NPK','Indeco'])[1+floor(random()*5)],
        (ARRAY['SB302','FXJ68','R45','H9X','HP2500'])[1+floor(random()*5)],
        (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['bakimda','pasif'])[1+floor(random()*2)::int] END),
        (CURRENT_DATE - floor(random()*180)::int),
        (CURRENT_DATE + floor(random()*180)::int),
        'KIR-SN-' || lpad(i::text, 6, '0'),
        'RFIDEQ-KR' || lpad(i::text, 6, '0'),
        (ARRAY['Atlas Copco Turkiye','Furukawa Turkiye'])[1+floor(random()*2)],
        (ARRAY['ABC Tedarik','XYZ Makine'])[1+floor(random()*2)],
        (2014 + floor(random()*11))::int,
        'orta',
        (1.5 + random()*3)::numeric(12,2),
        (CURRENT_DATE - floor(random()*1800)::int),
        (CURRENT_DATE - floor(random()*900)::int),
        (CURRENT_DATE + floor(random()*900)::int)
    FROM generate_series(1, 15) i
    RETURNING ekipman_id
)
INSERT INTO kirici (ekipman_id, darbe_enerjisi, dakikadaki_darbe_sayisi, calisma_basinci, uc_tipi, gereken_yag_debisi)
SELECT
    ekipman_id,
    (500 + random()*2500)::numeric(12,2),
    (300 + floor(random()*400))::int,
    (100 + random()*100)::numeric(12,2),
    (ARRAY['sivri','kunt','yassi'])[1+floor(random()*3)],
    (40 + random()*60)::numeric(12,2)
FROM yeni_ekipman;

-- ============================================================
-- 5. VARDIYA (80 kayit) - LATERAL ile duzeltilmis rastgele FK secimi
-- ============================================================

WITH pp AS (SELECT array_agg(personel_id) ids FROM personel),
     pe AS (SELECT array_agg(ekipman_id) ids FROM ekipman)
INSERT INTO vardiya (
    isg_sorumlusu_id, teknik_sorumlusu_id, ekipman_id, vardiya_sorumlusu_personel_id,
    vardiya_adi, vardiya_olusturma_tarihi, vardiya_tarih, vardiya_baslangic_tarihi, vardiya_bitis_tarihi,
    supervizor, personel_sayisi, ekipman_sayisi, ekip_sayisi, durum, vardiya_tipi,
    toplam_vardiya_suresi, calisma_bolgesi, operasyon_tipi, risk_seviyesi, vardiya_notlari, ekipman_operatoru
)
SELECT
    pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
    pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
    pe.ids[1+floor(random()*array_length(pe.ids,1))::int],
    pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
    (ARRAY['Sabah Vardiyasi','Aksam Vardiyasi','Gece Vardiyasi'])[1+floor(random()*3)] || ' - ' || i,
    (CURRENT_TIMESTAMP - (floor(random()*90) || ' days')::interval),
    (CURRENT_DATE - floor(random()*90)::int),
    (CURRENT_TIMESTAMP - (floor(random()*90) || ' days')::interval),
    (CURRENT_TIMESTAMP - (floor(random()*90) || ' days')::interval + interval '8 hours'),
    (ARRAY['Ahmet Yilmaz','Mehmet Demir','Ali Kaya'])[1+floor(random()*3)],
    (5 + floor(random()*20))::int,
    (2 + floor(random()*8))::int,
    (1 + floor(random()*4))::int,
    (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['tamamlandi','iptal'])[1+floor(random()*2)::int] END),
    (ARRAY['gunduz','gece','ara_vardiya'])[1+floor(random()*3)],
    (6 + random()*4)::numeric(12,2),
    (ARRAY['A Bolgesi','B Bolgesi','C Bolgesi','Ana Ocak','Dis Saha'])[1+floor(random()*5)],
    (ARRAY['kazi','nakliye','bakim','sondaj','yukleme'])[1+floor(random()*5)],
    (ARRAY['dusuk','orta','yuksek'])[1+floor(random()*3)],
    CASE WHEN random() > 0.7 THEN 'Standart operasyon, ozel bir durum yok.' ELSE NULL END,
    (ARRAY['Ahmet Yilmaz','Mehmet Demir','Ali Kaya','Huseyin Sahin'])[1+floor(random()*4)]
FROM generate_series(1, 80) i, pp, pe;

-- ============================================================
-- 6. EKIP (150 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH pp AS (SELECT array_agg(personel_id) ids FROM personel),
     pv AS (SELECT array_agg(vardiya_id) ids FROM vardiya)
INSERT INTO ekip (personel_id, vardiya_id, ekip_uye_sayisi, personel_gorev, durum)
SELECT
    pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
    pv.ids[1+floor(random()*array_length(pv.ids,1))::int],
    (2 + floor(random()*6))::int,
    (ARRAY['operator','yardimci','teknisyen','gozetmen'])[1+floor(random()*4)],
    (CASE WHEN random() < 0.9 THEN 'aktif' ELSE 'pasif' END)
FROM generate_series(1, 150) i, pp, pv;

-- ============================================================
-- 7. TAKIP CIHAZI (40 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH pp AS (SELECT array_agg(personel_id) ids FROM personel),
     pe AS (SELECT array_agg(ekipman_id) ids FROM ekipman)
INSERT INTO takip_cihazi (personel_id, ekipman_id, seri_no, cihaz_turu, model, durum, pil_seviyesi, son_sinyal_saati, son_sinyal_tarihi, haberlesme_protokolu)
SELECT
    CASE WHEN random() > 0.3 THEN pp.ids[1+floor(random()*array_length(pp.ids,1))::int] ELSE NULL END,
    CASE WHEN random() > 0.5 THEN pe.ids[1+floor(random()*array_length(pe.ids,1))::int] ELSE NULL END,
    'TKP-SN-' || lpad(i::text, 6, '0'),
    (ARRAY['GPS_yaka','GPS_kolye','RFID_bileklik','Ekipman_takip_modulu'])[1+floor(random()*4)],
    (ARRAY['TrackPro-100','SafeTag-X','GeoWear-2'])[1+floor(random()*3)],
    (CASE WHEN random() < 0.8 THEN 'aktif' ELSE (ARRAY['sinyal_yok','sarj_bekliyor'])[1+floor(random()*2)::int] END),
    (random()*100)::numeric(5,2),
    (CURRENT_TIME - (floor(random()*3600) || ' seconds')::interval),
    (CURRENT_TIMESTAMP - (floor(random()*48) || ' hours')::interval),
    (ARRAY['LoRaWAN','NB-IoT','Bluetooth','Wi-Fi'])[1+floor(random()*4)]
FROM generate_series(1, 40) i, pp, pe;

-- ============================================================
-- 8. SENSOR VERISI (500 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH ps AS (SELECT array_agg(ekipman_id) ids FROM sensor),
     pe AS (SELECT array_agg(ekipman_id) ids FROM ekipman)
INSERT INTO sensor_verisi (sensor_ekipman_id, hedef_ekipman_id, olcum_tarihi, olcum_degeri, olcum_birimi, esik_deger_asildi_mi)
SELECT
    ps.ids[1+floor(random()*array_length(ps.ids,1))::int],
    pe.ids[1+floor(random()*array_length(pe.ids,1))::int],
    (CURRENT_TIMESTAMP - (floor(random()*720) || ' hours')::interval),
    (random()*500)::numeric(12,4),
    (ARRAY['celsius','bar','hz','ppm','%'])[1+floor(random()*5)],
    (random() > 0.92)
FROM generate_series(1, 500) i, ps, pe;

-- ============================================================
-- 9. LOG KAYDI (300 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH pp AS (SELECT array_agg(personel_id) ids FROM personel),
     psv AS (SELECT array_agg(sensor_veri_id) ids FROM sensor_verisi)
INSERT INTO log_kaydi (personel_id, sensor_veri_id, olay_zamani, islem_turu, aciklama, durum, ip_adresi, onem_seviyesi)
SELECT
    CASE WHEN random() > 0.2 THEN pp.ids[1+floor(random()*array_length(pp.ids,1))::int] ELSE NULL END,
    CASE WHEN random() > 0.5 THEN psv.ids[1+floor(random()*array_length(psv.ids,1))::int] ELSE NULL END,
    (CURRENT_TIMESTAMP - (floor(random()*2000) || ' hours')::interval),
    (ARRAY['giris','cikis','veri_guncelleme','sistem_uyarisi','bakim_kaydi'])[1+floor(random()*5)],
    (ARRAY['Kullanici sisteme giris yapti','Ekipman durumu guncellendi','Otomatik esik asim uyarisi','Periyodik bakim kaydi olusturuldu'])[1+floor(random()*4)],
    (CASE WHEN random() < 0.9 THEN 'basarili' ELSE (ARRAY['basarisiz','beklemede'])[1+floor(random()*2)::int] END),
    '10.0.' || floor(random()*255)::text || '.' || floor(random()*255)::text,
    (ARRAY['dusuk','orta','yuksek','kritik'])[1+floor(random()*4)]
FROM generate_series(1, 300) i, pp, psv;

-- ============================================================
-- 10. VAKA (40 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH pe AS (SELECT array_agg(ekipman_id) ids FROM ekipman),
     pp AS (SELECT array_agg(personel_id) ids FROM personel),
     psv AS (SELECT array_agg(sensor_veri_id) ids FROM sensor_verisi)
INSERT INTO vaka (
    ilgili_ekipman_id, raporlayan_personel_id, raporlayan_sensor_veri_id,
    vaka_turu, vaka_adi, ciddiyet_seviyesi, durum, cozum_ekibi,
    olusturulma_tarihi, saat, vaka_olusturan, kapanis_tarihi, olay_nedeni, vaka_aciklamasi
)
SELECT
    pe.ids[1+floor(random()*array_length(pe.ids,1))::int],
    pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
    CASE WHEN random() > 0.5 THEN psv.ids[1+floor(random()*array_length(psv.ids,1))::int] ELSE NULL END,
    (ARRAY['ekipman_arizasi','is_kazasi_riski','esik_asimi','yakit_sizintisi','elektrik_arizasi'])[1+floor(random()*5)],
    'Vaka-' || lpad(i::text, 4, '0'),
    (ARRAY['dusuk','orta','yuksek','kritik'])[1+floor(random()*4)],
    (ARRAY['acik','inceleniyor','cozuldu','kapatildi'])[1+floor(random()*4)],
    (ARRAY['A Ekibi','B Ekibi','Acil Mudahale Ekibi'])[1+floor(random()*3)],
    (CURRENT_TIMESTAMP - (floor(random()*1000) || ' hours')::interval),
    (CURRENT_TIME - (floor(random()*43200) || ' seconds')::interval),
    (ARRAY['Ahmet Yilmaz','Mehmet Demir','Sensor Sistemi'])[1+floor(random()*3)],
    CASE WHEN random() > 0.4 THEN (CURRENT_TIMESTAMP - (floor(random()*500) || ' hours')::interval) ELSE NULL END,
    (ARRAY['Asiri isinma','Mekanik yorulma','Operator hatasi','Bakim eksikligi','Cevresel faktor'])[1+floor(random()*5)],
    'Otomatik olusturulmus test/ornek vaka kaydi - detaylar incelenmelidir.'
FROM generate_series(1, 40) i, pe, pp, psv;

-- ============================================================
-- 11. AKSIYON (60 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH pv AS (SELECT array_agg(vaka_id) ids FROM vaka),
     pek AS (SELECT array_agg(ekip_id) ids FROM ekip)
INSERT INTO aksiyon (vaka_id, ekip_id, mudahale_baslangic_saati, mudahale_bitis_saati, mudahale_turu, uygulanan_cozum)
SELECT
    pv.ids[1+floor(random()*array_length(pv.ids,1))::int],
    CASE WHEN random() > 0.2 THEN pek.ids[1+floor(random()*array_length(pek.ids,1))::int] ELSE NULL END,
    (CURRENT_TIMESTAMP - (floor(random()*800) || ' hours')::interval),
    (CURRENT_TIMESTAMP - (floor(random()*800) || ' hours')::interval + (floor(random()*4) || ' hours')::interval),
    (ARRAY['acil_mudahale','planli_bakim','parca_degisimi','yeniden_kalibrasyon','egitim'])[1+floor(random()*5)],
    (ARRAY['Parca degistirildi ve sistem test edildi.','Ekipman gecici olarak devre disi birakildi.','Personel bilgilendirildi, prosedur guncellendi.'])[1+floor(random()*3)]
FROM generate_series(1, 60) i, pv, pek;

-- ============================================================
-- 12. RAPOR + ALT TIPLERI (30 kayit: 15 personel, 15 ekipman)
-- ============================================================

-- --- Personel Raporu ---
WITH pp AS (SELECT array_agg(personel_id) ids FROM personel),
     yeni_rapor AS (
    INSERT INTO rapor (olusturan_id, rapor_adi, rapor_turu, olusturulma_tarihi, zaman_araligi)
    SELECT
        pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
        'Personel Performans Raporu - ' || i,
        'personel_raporu',
        (CURRENT_TIMESTAMP - (floor(random()*180) || ' days')::interval),
        (ARRAY['haftalik','aylik','ceyreklik'])[1+floor(random()*3)]
    FROM generate_series(1, 15) i, pp
    RETURNING rapor_id
)
INSERT INTO personel_raporu (rapor_id, uzmanlik_alani, personel_sayisi, calisma_suresi)
SELECT
    rapor_id,
    (ARRAY['Operasyon','ISG','Bakim','Lojistik'])[1+floor(random()*4)],
    (10 + floor(random()*40))::int,
    (100 + random()*400)::numeric(12,2)
FROM yeni_rapor;

-- --- Ekipman Raporu ---
WITH pp AS (SELECT array_agg(personel_id) ids FROM personel),
     yeni_rapor AS (
    INSERT INTO rapor (olusturan_id, rapor_adi, rapor_turu, olusturulma_tarihi, zaman_araligi)
    SELECT
        pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
        'Ekipman Performans Raporu - ' || i,
        'ekipman_raporu',
        (CURRENT_TIMESTAMP - (floor(random()*180) || ' days')::interval),
        (ARRAY['haftalik','aylik','ceyreklik'])[1+floor(random()*3)]
    FROM generate_series(1, 15) i, pp
    RETURNING rapor_id
)
INSERT INTO ekipman_raporu (rapor_id, ekipman_turu, ariza_sayisi, calisma_suresi)
SELECT
    rapor_id,
    (ARRAY['ekskavator','hafriyat','el_aleti','kepce','sensor','kirici'])[1+floor(random()*6)],
    (floor(random()*10))::int,
    (200 + random()*600)::numeric(12,2)
FROM yeni_rapor;

-- ============================================================
-- 13. VAKA RAPORU (40 kayit) - LATERAL ile duzeltilmis
-- ============================================================

WITH pr AS (SELECT array_agg(rapor_id) ids FROM rapor),
     pv AS (SELECT array_agg(vaka_id) ids FROM vaka),
     pp AS (SELECT array_agg(personel_id) ids FROM personel)
INSERT INTO vaka_raporu (rapor_id, vaka_id, raporlayan_id, ciddiyet_seviyesi, cozum_suresi)
SELECT
    CASE WHEN random() > 0.6 THEN pr.ids[1+floor(random()*array_length(pr.ids,1))::int] ELSE NULL END,
    pv.ids[1+floor(random()*array_length(pv.ids,1))::int],
    pp.ids[1+floor(random()*array_length(pp.ids,1))::int],
    (ARRAY['dusuk','orta','yuksek','kritik'])[1+floor(random()*4)],
    (1 + random()*48)::numeric(12,2)
FROM generate_series(1, 40) i, pr, pv, pp;

-- ============================================================
-- OZET: Eklenen kayit sayilarini goster
-- ============================================================

SELECT 'personel' AS tablo, count(*) AS kayit_sayisi FROM personel
UNION ALL SELECT 'saglik_bilgileri', count(*) FROM saglik_bilgileri
UNION ALL SELECT 'acil_durum_iletisim', count(*) FROM acil_durum_iletisim
UNION ALL SELECT 'ekipman', count(*) FROM ekipman
UNION ALL SELECT 'ekskavator', count(*) FROM ekskavator
UNION ALL SELECT 'hafriyat', count(*) FROM hafriyat
UNION ALL SELECT 'el_aletleri', count(*) FROM el_aletleri
UNION ALL SELECT 'kepce', count(*) FROM kepce
UNION ALL SELECT 'sensor', count(*) FROM sensor
UNION ALL SELECT 'kirici', count(*) FROM kirici
UNION ALL SELECT 'vardiya', count(*) FROM vardiya
UNION ALL SELECT 'ekip', count(*) FROM ekip
UNION ALL SELECT 'takip_cihazi', count(*) FROM takip_cihazi
UNION ALL SELECT 'sensor_verisi', count(*) FROM sensor_verisi
UNION ALL SELECT 'log_kaydi', count(*) FROM log_kaydi
UNION ALL SELECT 'vaka', count(*) FROM vaka
UNION ALL SELECT 'aksiyon', count(*) FROM aksiyon
UNION ALL SELECT 'rapor', count(*) FROM rapor
UNION ALL SELECT 'personel_raporu', count(*) FROM personel_raporu
UNION ALL SELECT 'ekipman_raporu', count(*) FROM ekipman_raporu
UNION ALL SELECT 'vaka_raporu', count(*) FROM vaka_raporu
ORDER BY tablo;

-- ============================================================
-- CESITLILIK KONTROLU: ekip tablosunda kac farkli personel/vardiya var?
-- (Bu sorgu, duzeltmenin gercekten calistigini dogrulamak icindir)
-- ============================================================

SELECT
    count(DISTINCT personel_id) AS farkli_personel_sayisi,
    count(DISTINCT vardiya_id) AS farkli_vardiya_sayisi,
    count(*) AS toplam_ekip_kaydi
FROM ekip;
