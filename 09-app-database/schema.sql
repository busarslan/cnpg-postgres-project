-- ============================================================
-- MINEMATION - Saha Operasyon Veritabani Semasi (ERD'ye gore)
-- Hedef veritabani: saha_operasyon
--
-- Tasarim notlari / varsayimlar:
--  - Turkce ozel karakterler ASCII'ye cevrildi (or. "Ekskavatör" ->
--    ekskavator), cunku tirnaksiz Postgres tanimlayicilari ozel
--    karakterlerle her sorguda cift tirnak gerektirir.
--  - Ekipman'in alt tipleri (Ekskavator, Hafriyat, El_Aletleri,
--    Kepce, Sensor, Kirici) "table-per-type" deseniyle kuruldu:
--    her alt tip tablosunun PK'si, ayni zamanda ekipman_id'ye
--    referans veren bir FK'dir (paylasilan anahtar).
--  - Ayni sekilde Rapor'un alt tipleri (Personel_Raporu,
--    Ekipman_Raporu) rapor_id'yi paylasilan anahtar olarak kullanir.
--  - Sensor_Verisi'nde iki ayri ekipman_id iliskisi var: biri
--    olcumu yapan sensorun kendisi (sensor_ekipman_id), digeri
--    olcumun yapildigi hedef ekipman (hedef_ekipman_id).
--  - Vaka'daki "raporlayan (sensor, personel)" alani polimorfik
--    gorundugu icin, hem raporlayan_personel_id hem de
--    raporlayan_sensor_veri_id (ikisi de NULL olabilir) olarak
--    ayristirildi.
--  - Acil_Durum_Iletisim ve Saglik_Bilgileri'nde diyagramda PK
--    gosterilmemis; pratik olmasi icin surrogate PK eklendi.
--  - ENUM olarak belirtilen "durum" alanlari VARCHAR birakildi,
--    gercek degerler netlesince CHECK/ENUM'a cevrilebilir.
--  - DECIMAL/olculebilir alanlar NUMERIC(12,2) varsayildi.
-- ============================================================

-- ============================================================
-- 1. PERSONEL & CEKIRDEK MODUL
-- ============================================================

CREATE TABLE personel (
    personel_id                        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personel_ad                        VARCHAR(50) NOT NULL,
    personel_soyad                     VARCHAR(50) NOT NULL,
    uzmanlik                           VARCHAR(100),
    tckn                                CHAR(11) UNIQUE,
    sifre_hash                          VARCHAR(255) NOT NULL,
    durum                               VARCHAR(20),      -- ENUM (degerler belirlenecek)
    dogum_tarihi                        DATE,
    cinsiyet                            VARCHAR(10),      -- ENUM (degerler belirlenecek)
    tel_no                              VARCHAR(20),
    ikinci_tel_no                       VARCHAR(20),
    eposta                              VARCHAR(100) UNIQUE,
    adres                               TEXT,
    ise_giris_tarihi                    DATE,
    calisan_tipi                        VARCHAR(30),
    calisabildigi_ekipman_turleri       TEXT,
    rfid_kart_numarasi                  VARCHAR(50) UNIQUE,
    kullanici_rolu                      VARCHAR(30),
    departman                           VARCHAR(50)
);

CREATE TABLE acil_durum_iletisim (
    acil_id                       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personel_id                   INTEGER NOT NULL REFERENCES personel(personel_id) ON DELETE CASCADE,
    acil_durum_kisileri_ad        VARCHAR(50),
    acil_durum_kisileri_soyad     VARCHAR(50),
    acil_durum_kisileri_yakinlik  VARCHAR(50),
    acil_durum_kisileri_tel_no    VARCHAR(20)
);

CREATE TABLE saglik_bilgileri (
    saglik_id                      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personel_id                    INTEGER NOT NULL REFERENCES personel(personel_id) ON DELETE CASCADE,
    kan_grubu                      VARCHAR(5),
    saglik_durumu                  TEXT,
    kronik_hastaliklar             TEXT,
    alerjiler                      TEXT,
    saglik_calisma_kisitlamalari   TEXT
);

-- ============================================================
-- 2. EKIPMAN MODULU (ust tablo + alt tipler)
-- ============================================================

CREATE TABLE ekipman (
    ekipman_id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ekipman_adi                 VARCHAR(100) NOT NULL,
    ekipman_marka               VARCHAR(50),
    ekipman_model               VARCHAR(50),
    durum                       VARCHAR(20),      -- ENUM (degerler belirlenecek)
    son_bakim_tarihi            DATE,
    gelecek_bakim_tarihi        DATE,
    seri_no                     VARCHAR(50) UNIQUE,
    rfid_etiketi                VARCHAR(50),
    uretici_firma                VARCHAR(100),
    tedarikci_firma              VARCHAR(100),
    uretim_yili                 INTEGER,
    boyut                       VARCHAR(100),
    agirlik                     NUMERIC(12,2),
    satin_alma_tarihi           DATE,
    garanti_baslangic_tarihi    DATE,
    garanti_bitis_tarihi        DATE,
    teknik_dokuman              VARCHAR(255),
    kullanim_klavuzu            VARCHAR(255),
    garanti_belgesi             VARCHAR(255),
    bakim_formu                 VARCHAR(255),
    satin_alma_belgesi          VARCHAR(255)
);

-- Ekipman alt tipleri: PK = FK (paylasilan anahtar / table-per-type)

CREATE TABLE ekskavator (
    ekipman_id               INTEGER PRIMARY KEY REFERENCES ekipman(ekipman_id) ON DELETE CASCADE,
    plaka                    VARCHAR(15),
    kova_kapasite            NUMERIC(12,2),
    motor_gucu               NUMERIC(12,2),
    maksimum_kazi_derinligi  NUMERIC(12,2),
    palet_tipi               VARCHAR(50),
    bom_uzunlugu             NUMERIC(12,2)
);

CREATE TABLE hafriyat (
    ekipman_id              INTEGER PRIMARY KEY REFERENCES ekipman(ekipman_id) ON DELETE CASCADE,
    plaka                   VARCHAR(15),
    damper_hacmi            NUMERIC(12,2),
    azami_yuklu_agirlik     NUMERIC(12,2),
    dingil_sayisi           INTEGER
);

CREATE TABLE el_aletleri (
    ekipman_id           INTEGER PRIMARY KEY REFERENCES ekipman(ekipman_id) ON DELETE CASCADE,
    guc_kaynagi_tipi     VARCHAR(50),
    batarya_kapasitesi   NUMERIC(12,2),
    kullanim_amaci       TEXT
);

CREATE TABLE kepce (
    ekipman_id                     INTEGER PRIMARY KEY REFERENCES ekipman(ekipman_id) ON DELETE CASCADE,
    plaka                          VARCHAR(15),
    yukleme_kapasitesi             NUMERIC(12,2),
    kova_genisligi                 NUMERIC(12,2),
    bosaltma_yuksekligi            NUMERIC(12,2),
    devrilme_yuku                  NUMERIC(12,2),
    saglik_calisma_kisitlamalari   TEXT
);

CREATE TABLE sensor (
    ekipman_id            INTEGER PRIMARY KEY REFERENCES ekipman(ekipman_id) ON DELETE CASCADE,
    sensor_tipi           VARCHAR(50),
    hassasiyet            NUMERIC(12,4),
    sensor_durumu         VARCHAR(20),   -- ENUM (degerler belirlenecek)
    olcum_araligi_max     NUMERIC(12,2),
    olcum_araligi_min     NUMERIC(12,2),
    haberlesme_tipi       VARCHAR(50),
    baglanti_protokolu    VARCHAR(50)
);

CREATE TABLE kirici (
    ekipman_id                  INTEGER PRIMARY KEY REFERENCES ekipman(ekipman_id) ON DELETE CASCADE,
    darbe_enerjisi              NUMERIC(12,2),
    dakikadaki_darbe_sayisi     INTEGER,
    calisma_basinci             NUMERIC(12,2),
    uc_tipi                     VARCHAR(50),
    gereken_yag_debisi          NUMERIC(12,2)
);

-- ============================================================
-- 3. VARDIYA & TAKIP MODULU
-- ============================================================

CREATE TABLE vardiya (
    vardiya_id                     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isg_sorumlusu_id               INTEGER REFERENCES personel(personel_id),
    teknik_sorumlusu_id            INTEGER REFERENCES personel(personel_id),
    ekipman_id                     INTEGER REFERENCES ekipman(ekipman_id),
    vardiya_sorumlusu_personel_id  INTEGER REFERENCES personel(personel_id),
    vardiya_adi                    VARCHAR(50),
    vardiya_olusturma_tarihi       TIMESTAMP,
    vardiya_tarih                  DATE,
    vardiya_baslangic_tarihi       TIMESTAMP,
    vardiya_bitis_tarihi           TIMESTAMP,
    supervizor                     VARCHAR(100),
    personel_sayisi                INTEGER,
    ekipman_sayisi                 INTEGER,
    ekip_sayisi                    INTEGER,
    durum                          VARCHAR(20),   -- ENUM (degerler belirlenecek)
    vardiya_tipi                   VARCHAR(30),
    toplam_vardiya_suresi          NUMERIC(12,2),
    calisma_bolgesi                VARCHAR(100),
    operasyon_tipi                 VARCHAR(50),
    risk_seviyesi                  VARCHAR(20),
    vardiya_notlari                TEXT,
    ekipman_operatoru              VARCHAR(100)
);

CREATE TABLE ekip (
    ekip_id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personel_id         INTEGER NOT NULL REFERENCES personel(personel_id),
    vardiya_id          INTEGER NOT NULL REFERENCES vardiya(vardiya_id),
    ekip_uye_sayisi     INTEGER,
    personel_gorev      VARCHAR(50),
    durum               VARCHAR(20)   -- ENUM (degerler belirlenecek)
);

CREATE TABLE takip_cihazi (
    takip_cihazi_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personel_id             INTEGER REFERENCES personel(personel_id),
    ekipman_id              INTEGER REFERENCES ekipman(ekipman_id),
    seri_no                 VARCHAR(50),
    cihaz_turu              VARCHAR(50),
    model                   VARCHAR(50),
    durum                   VARCHAR(20),   -- ENUM (degerler belirlenecek)
    pil_seviyesi            NUMERIC(5,2),
    son_sinyal_saati        TIME,
    son_sinyal_tarihi       TIMESTAMP,
    haberlesme_protokolu    VARCHAR(50)
);

-- Sensor_Verisi: sensoru olcen ekipman ile olcumun yapildigi hedef
-- ekipman ayri ayri iliskilendirildi (diyagramdaki iki "ekipman_id"
-- FK'sinin karsiligi).

CREATE TABLE sensor_verisi (
    sensor_veri_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sensor_ekipman_id        INTEGER NOT NULL REFERENCES sensor(ekipman_id),
    hedef_ekipman_id         INTEGER NOT NULL REFERENCES ekipman(ekipman_id),
    olcum_tarihi             TIMESTAMP,
    olcum_degeri             NUMERIC(12,4),
    olcum_birimi             VARCHAR(20),
    esik_deger_asildi_mi     BOOLEAN
);

CREATE TABLE log_kaydi (
    log_id             INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personel_id        INTEGER REFERENCES personel(personel_id),
    sensor_veri_id      INTEGER REFERENCES sensor_verisi(sensor_veri_id),
    olay_zamani        TIMESTAMP,
    islem_turu         VARCHAR(50),
    aciklama           TEXT,
    durum              VARCHAR(20),   -- ENUM (degerler belirlenecek)
    ip_adresi          VARCHAR(45),
    onem_seviyesi      VARCHAR(20)
);

-- ============================================================
-- 4. VAKA, AKSIYON & RAPOR MODULU
-- ============================================================

-- Vaka'daki "raporlayan (sensor, personel)" polimorfik gorundugu
-- icin iki ayri, birbirini disleyen (opsiyonel) FK olarak modellendi.

CREATE TABLE vaka (
    vaka_id                     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ilgili_ekipman_id           INTEGER REFERENCES ekipman(ekipman_id),
    raporlayan_personel_id      INTEGER REFERENCES personel(personel_id),
    raporlayan_sensor_veri_id   INTEGER REFERENCES sensor_verisi(sensor_veri_id),
    vaka_turu                   VARCHAR(50),
    vaka_adi                    VARCHAR(100),
    ciddiyet_seviyesi           VARCHAR(20),
    durum                       VARCHAR(20),   -- ENUM (degerler belirlenecek)
    cozum_ekibi                 VARCHAR(100),
    olusturulma_tarihi          TIMESTAMP,
    saat                        TIME,
    vaka_olusturan              VARCHAR(100),
    kapanis_tarihi              TIMESTAMP,
    olay_nedeni                 TEXT,
    vaka_aciklamasi             TEXT
);

CREATE TABLE aksiyon (
    mudahale_id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vaka_id                      INTEGER NOT NULL REFERENCES vaka(vaka_id),
    ekip_id                      INTEGER REFERENCES ekip(ekip_id),
    mudahale_baslangic_saati     TIMESTAMP,
    mudahale_bitis_saati         TIMESTAMP,
    mudahale_turu                VARCHAR(50),
    uygulanan_cozum              TEXT
);

CREATE TABLE rapor (
    rapor_id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    olusturan_id           INTEGER REFERENCES personel(personel_id),
    rapor_adi              VARCHAR(100),
    rapor_turu             VARCHAR(50),
    olusturulma_tarihi     TIMESTAMP,
    zaman_araligi          VARCHAR(50)
);

-- Rapor alt tipleri: PK = FK (paylasilan anahtar)

CREATE TABLE personel_raporu (
    rapor_id             INTEGER PRIMARY KEY REFERENCES rapor(rapor_id) ON DELETE CASCADE,
    uzmanlik_alani       VARCHAR(100),
    personel_sayisi      INTEGER,
    calisma_suresi       NUMERIC(12,2)
);

CREATE TABLE ekipman_raporu (
    rapor_id           INTEGER PRIMARY KEY REFERENCES rapor(rapor_id) ON DELETE CASCADE,
    ekipman_turu       VARCHAR(50),
    ariza_sayisi       INTEGER,
    calisma_suresi     NUMERIC(12,2)
);

-- Vaka_Raporu, diyagramda Rapor ailesiyle birlikte gosterilse de
-- kendi FK'lari (vaka_id, raporlayan_id) uzerinden ayri bir tablo
-- olarak modellendi; istege bagli rapor_id baglantisi da eklendi.

CREATE TABLE vaka_raporu (
    vaka_rapor_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rapor_id             INTEGER REFERENCES rapor(rapor_id),
    vaka_id              INTEGER NOT NULL REFERENCES vaka(vaka_id),
    raporlayan_id        INTEGER REFERENCES personel(personel_id),
    ciddiyet_seviyesi    VARCHAR(20),
    cozum_suresi         NUMERIC(12,2)
);

-- ============================================================
-- Faydali indeksler
-- ============================================================

CREATE INDEX idx_acil_durum_personel ON acil_durum_iletisim(personel_id);
CREATE INDEX idx_saglik_bilgileri_personel ON saglik_bilgileri(personel_id);
CREATE INDEX idx_vardiya_isg ON vardiya(isg_sorumlusu_id);
CREATE INDEX idx_vardiya_teknik ON vardiya(teknik_sorumlusu_id);
CREATE INDEX idx_vardiya_ekipman ON vardiya(ekipman_id);
CREATE INDEX idx_vardiya_sorumlu ON vardiya(vardiya_sorumlusu_personel_id);
CREATE INDEX idx_ekip_personel ON ekip(personel_id);
CREATE INDEX idx_ekip_vardiya ON ekip(vardiya_id);
CREATE INDEX idx_takip_cihazi_personel ON takip_cihazi(personel_id);
CREATE INDEX idx_takip_cihazi_ekipman ON takip_cihazi(ekipman_id);
CREATE INDEX idx_sensor_verisi_sensor ON sensor_verisi(sensor_ekipman_id);
CREATE INDEX idx_sensor_verisi_hedef ON sensor_verisi(hedef_ekipman_id);
CREATE INDEX idx_sensor_verisi_tarih ON sensor_verisi(olcum_tarihi);
CREATE INDEX idx_log_kaydi_personel ON log_kaydi(personel_id);
CREATE INDEX idx_log_kaydi_sensor_verisi ON log_kaydi(sensor_veri_id);
CREATE INDEX idx_log_kaydi_zaman ON log_kaydi(olay_zamani);
CREATE INDEX idx_vaka_ekipman ON vaka(ilgili_ekipman_id);
CREATE INDEX idx_vaka_personel ON vaka(raporlayan_personel_id);
CREATE INDEX idx_aksiyon_vaka ON aksiyon(vaka_id);
CREATE INDEX idx_aksiyon_ekip ON aksiyon(ekip_id);
CREATE INDEX idx_rapor_olusturan ON rapor(olusturan_id);
CREATE INDEX idx_vaka_raporu_vaka ON vaka_raporu(vaka_id);
CREATE INDEX idx_vaka_raporu_raporlayan ON vaka_raporu(raporlayan_id);
