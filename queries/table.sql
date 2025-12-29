CREATE TABLE pelanggan (
  pelanggan_id INT AUTO_INCREMENT PRIMARY KEY,
  nama         VARCHAR(150) NOT NULL,
  no_hp        VARCHAR(30),
  email        VARCHAR(150)
) ENGINE=InnoDB;

CREATE TABLE perangkat (
  perangkat_id INT AUTO_INCREMENT PRIMARY KEY,
  pelanggan_id INT NOT NULL,
  imei_serial  VARCHAR(100) UNIQUE,
  merek        VARCHAR(100),
  model        VARCHAR(100),
  warna        VARCHAR(50),
  INDEX idx_perangkat_pelanggan (pelanggan_id),
  CONSTRAINT fk_perangkat_pelanggan FOREIGN KEY (pelanggan_id)
    REFERENCES pelanggan(pelanggan_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE staf (
  staf_id INT AUTO_INCREMENT PRIMARY KEY,
  nama    VARCHAR(150) NOT NULL,
  email   VARCHAR(50),
  role    VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE order_servis (
  order_id     INT AUTO_INCREMENT PRIMARY KEY,
  perangkat_id INT NOT NULL,
  dibuat_oleh  INT NOT NULL,
  status       VARCHAR(50),
  INDEX idx_order_perangkat (perangkat_id),
  INDEX idx_order_dibuat (dibuat_oleh),
  CONSTRAINT fk_order_perangkat FOREIGN KEY (perangkat_id)
    REFERENCES perangkat(perangkat_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_staf FOREIGN KEY (dibuat_oleh)
    REFERENCES staf(staf_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE diagnosa (
  diagnosa_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id    INT NOT NULL,
  teknisi_id  INT NOT NULL,
  diagnosis   VARCHAR(255),
  INDEX idx_diagnosa_order (order_id),
  INDEX idx_diagnosa_teknisi (teknisi_id),
  CONSTRAINT fk_diagnosa_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_diagnosa_teknisi FOREIGN KEY (teknisi_id)
    REFERENCES staf(staf_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE estimasi (
  estimasi_id    INT AUTO_INCREMENT PRIMARY KEY,
  order_id       INT NOT NULL,
  biaya_sparepart DECIMAL(12,2),
  biaya_jasa      DECIMAL(12,2),
  estimasi_kerja  DECIMAL(12,2),
  status          VARCHAR(50),
  INDEX idx_estimasi_order (order_id),
  CONSTRAINT fk_estimasi_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sparepart (
  sparepart_id INT AUTO_INCREMENT PRIMARY KEY,
  kode_sku     VARCHAR(100) UNIQUE,
  nama         VARCHAR(150) NOT NULL,
  harga_satuan DECIMAL(12,2) NOT NULL DEFAULT 0,
  stok_qty     INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE order_sparepart (
  order_id     INT NOT NULL,
  sparepart_id INT NOT NULL,
  jumlah       INT NOT NULL DEFAULT 1,
  harga        DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (order_id, sparepart_id),
  INDEX idx_os_order (order_id),
  INDEX idx_os_sparepart (sparepart_id),
  CONSTRAINT fk_os_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_os_sparepart FOREIGN KEY (sparepart_id)
    REFERENCES sparepart(sparepart_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pembayaran (
  pembayaran_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id      INT NOT NULL,
  jumlah_bayar  DECIMAL(12,2) NOT NULL,
  metode        VARCHAR(50),
  paid_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pembayaran_order (order_id),
  CONSTRAINT fk_pembayaran_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tagihan (
  tagihan_id    INT AUTO_INCREMENT PRIMARY KEY,
  order_id      INT NOT NULL UNIQUE,
  status_tagihan VARCHAR(50),
  total_biaya   DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_tagihan_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;
