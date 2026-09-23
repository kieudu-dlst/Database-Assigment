CREATE DATABASE QL_BanVeRapChieuPhim;
GO

USE QL_BanVeRapChieuPhim
GO

SET NOCOUNT ON;
GO

/*=============================================================================
  PHAN 1. TẠO BẢNG, KHÓA VÀ RẰNG BUỘC TOÀN VẸN DỮ LIỆU
=============================================================================*/

CREATE TABLE dbo.Phim
(
    Ma          VARCHAR(50)    NOT NULL,
    Ten         NVARCHAR(200)  NOT NULL,
    TheLoai     NVARCHAR(50)  NOT NULL,
    ThoiLuong   INT            NOT NULL,

    CONSTRAINT PK_Phim PRIMARY KEY (Ma),
    CONSTRAINT UQ_Phim_Ten UNIQUE (Ten),
    CONSTRAINT CK_Phim_ThoiLuong CHECK (ThoiLuong > 0)
);
GO

CREATE TABLE dbo.PhongChieu
(
    Ma      VARCHAR(50)    NOT NULL,
    Ten     NVARCHAR(100)  NOT NULL,

    CONSTRAINT PK_PhongChieu PRIMARY KEY (Ma),
    CONSTRAINT UQ_PhongChieu_Ten UNIQUE (Ten)
);
GO

CREATE TABLE dbo.Ghe
(
    Ma              VARCHAR(50)  NOT NULL,
    SoGhe           VARCHAR(10)  NOT NULL,
    MaPhongChieu    VARCHAR(50)  NOT NULL,

    CONSTRAINT PK_Ghe PRIMARY KEY (Ma),
    CONSTRAINT FK_Ghe_PhongChieu
        FOREIGN KEY (MaPhongChieu) REFERENCES dbo.PhongChieu(Ma),
    CONSTRAINT UQ_Ghe_Phong_SoGhe UNIQUE (MaPhongChieu, SoGhe)
);
GO

CREATE TABLE dbo.SuatChieu
(
    Ma                  VARCHAR(50)    NOT NULL,
    ThoiGian            DATETIME2(0)   NOT NULL,
    GiaVe               DECIMAL(18,2)  NOT NULL,
    MaPhim              VARCHAR(50)    NOT NULL,
    MaPhongChieu        VARCHAR(50)    NOT NULL,
    SoLuongGheToiDa     INT            NOT NULL,

    CONSTRAINT PK_SuatChieu PRIMARY KEY (Ma),
    CONSTRAINT FK_SuatChieu_Phim
        FOREIGN KEY (MaPhim) REFERENCES dbo.Phim(Ma),
    CONSTRAINT FK_SuatChieu_PhongChieu
        FOREIGN KEY (MaPhongChieu) REFERENCES dbo.PhongChieu(Ma),
    CONSTRAINT CK_SuatChieu_GiaVe CHECK (GiaVe > 0),
    CONSTRAINT CK_SuatChieu_SoLuongGheToiDa CHECK (SoLuongGheToiDa > 0),
    CONSTRAINT UQ_SuatChieu_Phong_ThoiGian
        UNIQUE (MaPhongChieu, ThoiGian)
);
GO

CREATE TABLE dbo.KhachHang
(
    Ma      VARCHAR(50)    NOT NULL,
    HoTen   NVARCHAR(100)  NOT NULL,
    SDT     VARCHAR(15)    NOT NULL,
    Email   VARCHAR(200)   NOT NULL,

    CONSTRAINT PK_KhachHang PRIMARY KEY (Ma),
    CONSTRAINT UQ_KhachHang_SDT UNIQUE (SDT),
    CONSTRAINT UQ_KhachHang_Email UNIQUE (Email),
    CONSTRAINT CK_KhachHang_SDT
        CHECK (LEN(SDT) >= 10 AND SDT NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_KhachHang_Email
        CHECK (Email LIKE '%_@_%._%')
);
GO

CREATE TABLE dbo.HoaDon
(
    Ma              VARCHAR(50)    NOT NULL,
    NgayMua         DATETIME2(0)   NOT NULL
        CONSTRAINT DF_HoaDon_NgayMua DEFAULT SYSDATETIME(),
    MaKhachHang     VARCHAR(50)    NOT NULL,
    SoTien          DECIMAL(18,2)  NOT NULL,

    CONSTRAINT PK_HoaDon PRIMARY KEY (Ma),
    CONSTRAINT FK_HoaDon_KhachHang
        FOREIGN KEY (MaKhachHang) REFERENCES dbo.KhachHang(Ma),
    CONSTRAINT CK_HoaDon_SoTien CHECK (SoTien > 0)
);
GO

CREATE TABLE dbo.Ve
(
    Ma              VARCHAR(50)  NOT NULL,
    MaGhe           VARCHAR(50)  NOT NULL,
    MaSuatChieu     VARCHAR(50)  NOT NULL,
    MaHoaDon        VARCHAR(50)  NOT NULL,

    CONSTRAINT PK_Ve PRIMARY KEY (Ma),
    CONSTRAINT FK_Ve_Ghe
        FOREIGN KEY (MaGhe) REFERENCES dbo.Ghe(Ma),
    CONSTRAINT FK_Ve_SuatChieu
        FOREIGN KEY (MaSuatChieu) REFERENCES dbo.SuatChieu(Ma),
    CONSTRAINT FK_Ve_HoaDon
        FOREIGN KEY (MaHoaDon) REFERENCES dbo.HoaDon(Ma),
    CONSTRAINT UQ_Ve_SuatChieu_Ghe UNIQUE (MaSuatChieu, MaGhe)
);
GO

CREATE TABLE dbo.ThanhToan
(
    Ma          VARCHAR(50)   NOT NULL,
    TrangThai   VARCHAR(20)   NOT NULL,
    PhuongThuc  VARCHAR(30)   NOT NULL,
    ThoiGian    DATETIME2(0)  NOT NULL
        CONSTRAINT DF_ThanhToan_ThoiGian DEFAULT SYSDATETIME(),
    MaHoaDon    VARCHAR(50)   NOT NULL,

    CONSTRAINT PK_ThanhToan PRIMARY KEY (Ma),
    CONSTRAINT FK_ThanhToan_HoaDon
        FOREIGN KEY (MaHoaDon) REFERENCES dbo.HoaDon(Ma),
    CONSTRAINT CK_ThanhToan_TrangThai
        CHECK (TrangThai IN ('Thanh cong', 'That bai', 'Hoan tien')),
    CONSTRAINT CK_ThanhToan_PhuongThuc
        CHECK (PhuongThuc IN ('Tien mat', 'Chuyen khoan', 'The', 'Vi dien tu'))
);
GO

CREATE UNIQUE INDEX UX_ThanhToan_ThanhCong
ON dbo.ThanhToan(MaHoaDon)
WHERE TrangThai = 'Thanh cong';
GO

CREATE UNIQUE INDEX UX_ThanhToan_HoanTien
ON dbo.ThanhToan(MaHoaDon)
WHERE TrangThai = 'Hoan tien';
GO

CREATE INDEX IX_Ghe_MaPhongChieu ON dbo.Ghe(MaPhongChieu);
CREATE INDEX IX_SuatChieu_MaPhim_ThoiGian ON dbo.SuatChieu(MaPhim, ThoiGian);
CREATE INDEX IX_HoaDon_MaKhachHang_NgayMua ON dbo.HoaDon(MaKhachHang, NgayMua);
CREATE INDEX IX_Ve_MaHoaDon ON dbo.Ve(MaHoaDon);
CREATE INDEX IX_ThanhToan_MaHoaDon_ThoiGian ON dbo.ThanhToan(MaHoaDon, ThoiGian);
GO

/*=============================================================================
  PHAN 2. TRIGGER KIỂM SOÁT NGHIỆP VỤ
=============================================================================*/

-- Trigger 1: SoLuongGheToiDa của suất chiếu không được vượt quá số ghế của phòng chiếu.
CREATE TRIGGER dbo.trg_SuatChieu_KiemTraGioiHanGhe
ON dbo.SuatChieu
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        WHERE i.SoLuongGheToiDa >
              (
                  SELECT COUNT(*)
                  FROM dbo.Ghe AS g
                  WHERE g.MaPhongChieu = i.MaPhongChieu
              )
    )
    BEGIN
        RAISERROR(
            N'SoLuongGheToiDa khong duoc vuot qua so ghe cua phong chieu.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- CHẠY THỬ TRIGGER 1: chặn sức chứa vượt số ghế.
IF EXISTS (SELECT 1 FROM dbo.Phim WHERE Ma = 'P001')
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT dbo.SuatChieu
            (Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa)
        VALUES ('SCERR01', '2030-01-01T09:00:00', 80000, 'P001', 'PC01', 999);
        ROLLBACK TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT N'Test Trigger 1' AS KiemThu, ERROR_MESSAGE() AS KetQuaMongDoi;
    END CATCH;
END;
GO

-- Trigger 2: Kiểm tra ghế đúng phòng và cập nhật tổng tiền hóa đơn.
CREATE TRIGGER dbo.trg_Ve_KiemTraDatGhe
ON dbo.Ve
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        JOIN dbo.Ghe AS g ON g.Ma = i.MaGhe
        JOIN dbo.SuatChieu AS sc ON sc.Ma = i.MaSuatChieu
        WHERE g.MaPhongChieu <> sc.MaPhongChieu
    )
    BEGIN
        RAISERROR(
            N'Ghe duoc chon khong thuoc phong cua suat chieu.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    UPDATE hd
    SET SoTien =
        (
            SELECT SUM(sc.GiaVe)
            FROM dbo.Ve AS v
            JOIN dbo.SuatChieu AS sc ON sc.Ma = v.MaSuatChieu
            WHERE v.MaHoaDon = hd.Ma
        )
    FROM dbo.HoaDon AS hd
    WHERE hd.Ma IN
          (
              SELECT MaHoaDon FROM inserted
              UNION
              SELECT MaHoaDon FROM deleted
          );
END;
GO

-- CHẠY THỬ TRIGGER 2A: chặn ghế sai phòng.
IF EXISTS (SELECT 1 FROM dbo.SuatChieu WHERE Ma = 'SC0001')
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT dbo.HoaDon(Ma, NgayMua, MaKhachHang, SoTien)
        VALUES ('HDERR03', '2026-08-01T07:00:00', 'KH025', 70000);
        INSERT dbo.Ve(Ma, MaGhe, MaSuatChieu, MaHoaDon)
        VALUES ('VERR03', 'G02003', 'SC0001', 'HDERR03');
        ROLLBACK TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT N'Test Trigger 2A' AS KiemThu, ERROR_MESSAGE() AS KetQuaMongDoi;
    END CATCH;
END;
GO

-- CHẠY THỬ TRIGGER 2B: tự cập nhật tổng tiền.
IF OBJECT_ID(N'dbo.sp_DatVe', N'P') IS NOT NULL
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC dbo.sp_DatVe 'HDTEST5', 'KH025', 'VTEST51', 'SC0030', 'G05003', '2026-08-06T12:00:00';
        SELECT N'Sau vé 1' AS Buoc, SoTien FROM dbo.HoaDon WHERE Ma = 'HDTEST5';
        EXEC dbo.sp_DatVe 'HDTEST5', 'KH025', 'VTEST52', 'SC0030', 'G05004', NULL;
        SELECT N'Sau vé 2' AS Buoc, SoTien FROM dbo.HoaDon WHERE Ma = 'HDTEST5';
        ROLLBACK TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        SELECT N'Test Trigger 2B' AS KiemThu, ERROR_MESSAGE() AS KetQua;
    END CATCH;
END;
GO

/*=============================================================================
  PHAN 3. DỮ LIỆU DEMO 
=============================================================================*/

-- 3.1. Dữ liệu Phim
INSERT INTO dbo.Phim(Ma, Ten, TheLoai, ThoiLuong)
VALUES
('P001', N'Mua Do',                 N'Tam ly',            105),
('P002', N'Hanh Tinh Xanh',         N'Khoa hoc vien tuong', 130),
('P003', N'Chuyen Tau Dem',         N'Kinh di',            98),
('P004', N'Ngay Nang Tro Lai',      N'Tinh cam',          112),
('P005', N'Biet Doi Cuoi Cung',     N'Hanh dong',         125),
('P006', N'Ky Uc Mua He',           N'Gia dinh',          101),
('P007', N'Thanh Pho Khong Ngu',    N'Hinh su',           118),
('P008', N'Nguoi Gac Rung',         N'Phieu luu',         109),
('P009', N'Tieng Goi Dai Duong',    N'Hoat hinh',          95),
('P010', N'Bi Mat Can Phong 7',     N'Kinh di',           102),
('P011', N'Duong Dua Cuoi Tuan',    N'Hanh dong',         116),
('P012', N'Ban Nhac Thanh Xuan',    N'Am nhac',           110),
('P013', N'Vu An Trong Mua',        N'Trinh tham',        121),
('P014', N'Chiec Dong Ho Cu',       N'Khoa hoc vien tuong', 127),
('P015', N'Nha Co Ba Nguoi',        N'Gia dinh',           99),
('P016', N'Chuyen Ke Tu Sao Hoa',   N'Khoa hoc vien tuong', 134),
('P017', N'Mua Tren Pho Nho',       N'Tinh cam',          107),
('P018', N'Nhung Nguoi Ban',        N'Hai',               103),
('P019', N'Vuon Hoa Cuoi Pho',      N'Tam ly',            114),
('P020', N'Anh Sang Cuoi Duong',    N'Chinh kich',        120);
GO

-- 3.2. Dữ liệu PhongChieu
INSERT INTO dbo.PhongChieu(Ma, Ten)
VALUES
('PC01', N'Phong 1 - Standard'),
('PC02', N'Phong 2 - Standard'),
('PC03', N'Phong 3 - Large'),
('PC04', N'Phong 4 - Premium'),
('PC05', N'Phong 5 - Standard');
GO

-- 3.3. Dữ liệu Ghe
INSERT INTO dbo.Ghe(Ma, SoGhe, MaPhongChieu)
VALUES
('G01001', 'A01', 'PC01'),
('G01002', 'A02', 'PC01'),
('G01003', 'A03', 'PC01'),
('G01004', 'A04', 'PC01'),
('G01005', 'A05', 'PC01'),
('G01006', 'A06', 'PC01'),
('G01007', 'A07', 'PC01'),
('G01008', 'A08', 'PC01'),
('G01009', 'A09', 'PC01'),
('G01010', 'A10', 'PC01'),
('G01011', 'B01', 'PC01'),
('G01012', 'B02', 'PC01'),
('G01013', 'B03', 'PC01'),
('G01014', 'B04', 'PC01'),
('G01015', 'B05', 'PC01'),
('G01016', 'B06', 'PC01'),
('G01017', 'B07', 'PC01'),
('G01018', 'B08', 'PC01'),
('G01019', 'B09', 'PC01'),
('G01020', 'B10', 'PC01'),
('G01021', 'C01', 'PC01'),
('G01022', 'C02', 'PC01'),
('G01023', 'C03', 'PC01'),
('G01024', 'C04', 'PC01'),
('G01025', 'C05', 'PC01'),
('G01026', 'C06', 'PC01'),
('G01027', 'C07', 'PC01'),
('G01028', 'C08', 'PC01'),
('G01029', 'C09', 'PC01'),
('G01030', 'C10', 'PC01');

INSERT INTO dbo.Ghe(Ma, SoGhe, MaPhongChieu)
VALUES
('G02001', 'A01', 'PC02'),
('G02002', 'A02', 'PC02'),
('G02003', 'A03', 'PC02'),
('G02004', 'A04', 'PC02'),
('G02005', 'A05', 'PC02'),
('G02006', 'A06', 'PC02'),
('G02007', 'A07', 'PC02'),
('G02008', 'A08', 'PC02'),
('G02009', 'A09', 'PC02'),
('G02010', 'A10', 'PC02'),
('G02011', 'B01', 'PC02'),
('G02012', 'B02', 'PC02'),
('G02013', 'B03', 'PC02'),
('G02014', 'B04', 'PC02'),
('G02015', 'B05', 'PC02'),
('G02016', 'B06', 'PC02'),
('G02017', 'B07', 'PC02'),
('G02018', 'B08', 'PC02'),
('G02019', 'B09', 'PC02'),
('G02020', 'B10', 'PC02'),
('G02021', 'C01', 'PC02'),
('G02022', 'C02', 'PC02'),
('G02023', 'C03', 'PC02'),
('G02024', 'C04', 'PC02'),
('G02025', 'C05', 'PC02'),
('G02026', 'C06', 'PC02'),
('G02027', 'C07', 'PC02'),
('G02028', 'C08', 'PC02'),
('G02029', 'C09', 'PC02'),
('G02030', 'C10', 'PC02'),
('G02031', 'D01', 'PC02'),
('G02032', 'D02', 'PC02'),
('G02033', 'D03', 'PC02'),
('G02034', 'D04', 'PC02'),
('G02035', 'D05', 'PC02'),
('G02036', 'D06', 'PC02'),
('G02037', 'D07', 'PC02'),
('G02038', 'D08', 'PC02'),
('G02039', 'D09', 'PC02'),
('G02040', 'D10', 'PC02');

INSERT INTO dbo.Ghe(Ma, SoGhe, MaPhongChieu)
VALUES
('G03001', 'A01', 'PC03'),
('G03002', 'A02', 'PC03'),
('G03003', 'A03', 'PC03'),
('G03004', 'A04', 'PC03'),
('G03005', 'A05', 'PC03'),
('G03006', 'A06', 'PC03'),
('G03007', 'A07', 'PC03'),
('G03008', 'A08', 'PC03'),
('G03009', 'A09', 'PC03'),
('G03010', 'A10', 'PC03'),
('G03011', 'B01', 'PC03'),
('G03012', 'B02', 'PC03'),
('G03013', 'B03', 'PC03'),
('G03014', 'B04', 'PC03'),
('G03015', 'B05', 'PC03'),
('G03016', 'B06', 'PC03'),
('G03017', 'B07', 'PC03'),
('G03018', 'B08', 'PC03'),
('G03019', 'B09', 'PC03'),
('G03020', 'B10', 'PC03'),
('G03021', 'C01', 'PC03'),
('G03022', 'C02', 'PC03'),
('G03023', 'C03', 'PC03'),
('G03024', 'C04', 'PC03'),
('G03025', 'C05', 'PC03'),
('G03026', 'C06', 'PC03'),
('G03027', 'C07', 'PC03'),
('G03028', 'C08', 'PC03'),
('G03029', 'C09', 'PC03'),
('G03030', 'C10', 'PC03'),
('G03031', 'D01', 'PC03'),
('G03032', 'D02', 'PC03'),
('G03033', 'D03', 'PC03'),
('G03034', 'D04', 'PC03'),
('G03035', 'D05', 'PC03'),
('G03036', 'D06', 'PC03'),
('G03037', 'D07', 'PC03'),
('G03038', 'D08', 'PC03'),
('G03039', 'D09', 'PC03'),
('G03040', 'D10', 'PC03'),
('G03041', 'E01', 'PC03'),
('G03042', 'E02', 'PC03'),
('G03043', 'E03', 'PC03'),
('G03044', 'E04', 'PC03'),
('G03045', 'E05', 'PC03'),
('G03046', 'E06', 'PC03'),
('G03047', 'E07', 'PC03'),
('G03048', 'E08', 'PC03'),
('G03049', 'E09', 'PC03'),
('G03050', 'E10', 'PC03');

INSERT INTO dbo.Ghe(Ma, SoGhe, MaPhongChieu)
VALUES
('G04001', 'A01', 'PC04'),
('G04002', 'A02', 'PC04'),
('G04003', 'A03', 'PC04'),
('G04004', 'A04', 'PC04'),
('G04005', 'A05', 'PC04'),
('G04006', 'A06', 'PC04'),
('G04007', 'A07', 'PC04'),
('G04008', 'A08', 'PC04'),
('G04009', 'A09', 'PC04'),
('G04010', 'A10', 'PC04'),
('G04011', 'B01', 'PC04'),
('G04012', 'B02', 'PC04'),
('G04013', 'B03', 'PC04'),
('G04014', 'B04', 'PC04'),
('G04015', 'B05', 'PC04'),
('G04016', 'B06', 'PC04'),
('G04017', 'B07', 'PC04'),
('G04018', 'B08', 'PC04'),
('G04019', 'B09', 'PC04'),
('G04020', 'B10', 'PC04'),
('G04021', 'C01', 'PC04'),
('G04022', 'C02', 'PC04'),
('G04023', 'C03', 'PC04'),
('G04024', 'C04', 'PC04'),
('G04025', 'C05', 'PC04'),
('G04026', 'C06', 'PC04'),
('G04027', 'C07', 'PC04'),
('G04028', 'C08', 'PC04'),
('G04029', 'C09', 'PC04'),
('G04030', 'C10', 'PC04'),
('G04031', 'D01', 'PC04'),
('G04032', 'D02', 'PC04'),
('G04033', 'D03', 'PC04'),
('G04034', 'D04', 'PC04'),
('G04035', 'D05', 'PC04'),
('G04036', 'D06', 'PC04'),
('G04037', 'D07', 'PC04'),
('G04038', 'D08', 'PC04'),
('G04039', 'D09', 'PC04'),
('G04040', 'D10', 'PC04');

INSERT INTO dbo.Ghe(Ma, SoGhe, MaPhongChieu)
VALUES
('G05001', 'A01', 'PC05'),
('G05002', 'A02', 'PC05'),
('G05003', 'A03', 'PC05'),
('G05004', 'A04', 'PC05'),
('G05005', 'A05', 'PC05'),
('G05006', 'A06', 'PC05'),
('G05007', 'A07', 'PC05'),
('G05008', 'A08', 'PC05'),
('G05009', 'A09', 'PC05'),
('G05010', 'A10', 'PC05'),
('G05011', 'B01', 'PC05'),
('G05012', 'B02', 'PC05'),
('G05013', 'B03', 'PC05'),
('G05014', 'B04', 'PC05'),
('G05015', 'B05', 'PC05'),
('G05016', 'B06', 'PC05'),
('G05017', 'B07', 'PC05'),
('G05018', 'B08', 'PC05'),
('G05019', 'B09', 'PC05'),
('G05020', 'B10', 'PC05'),
('G05021', 'C01', 'PC05'),
('G05022', 'C02', 'PC05'),
('G05023', 'C03', 'PC05'),
('G05024', 'C04', 'PC05'),
('G05025', 'C05', 'PC05'),
('G05026', 'C06', 'PC05'),
('G05027', 'C07', 'PC05'),
('G05028', 'C08', 'PC05'),
('G05029', 'C09', 'PC05'),
('G05030', 'C10', 'PC05');
GO

-- 3.4. Dữ liệu SuatChieu
INSERT INTO dbo.SuatChieu
(
    Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa
)
VALUES
('SC0001', '2026-08-01T09:00:00', 70000,  'P001', 'PC01', 30),
('SC0002', '2026-08-01T12:00:00', 80000,  'P002', 'PC02', 40),
('SC0003', '2026-08-01T15:00:00', 90000,  'P003', 'PC03', 50),
('SC0004', '2026-08-01T09:00:00', 100000, 'P004', 'PC04', 40),
('SC0005', '2026-08-01T12:00:00', 70000,  'P005', 'PC05', 30);

INSERT INTO dbo.SuatChieu
    (Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa)
VALUES
('SC0006', '2026-08-02T15:00:00', 80000,  'P006', 'PC01', 30),
('SC0007', '2026-08-02T09:00:00', 90000,  'P007', 'PC02', 40),
('SC0008', '2026-08-02T12:00:00', 100000, 'P008', 'PC03', 50),
('SC0009', '2026-08-02T15:00:00', 70000,  'P009', 'PC04', 40),
('SC0010', '2026-08-02T09:00:00', 80000,  'P010', 'PC05', 30);

INSERT INTO dbo.SuatChieu
    (Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa)
VALUES
('SC0011', '2026-08-03T12:00:00', 90000,  'P011', 'PC01', 30),
('SC0012', '2026-08-03T15:00:00', 100000, 'P012', 'PC02', 40),
('SC0013', '2026-08-03T09:00:00', 70000,  'P013', 'PC03', 50),
('SC0014', '2026-08-03T12:00:00', 80000,  'P014', 'PC04', 40),
('SC0015', '2026-08-03T15:00:00', 90000,  'P015', 'PC05', 30);

INSERT INTO dbo.SuatChieu
    (Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa)
VALUES
('SC0016', '2026-08-04T09:00:00', 100000, 'P016', 'PC01', 30),
('SC0017', '2026-08-04T12:00:00', 70000,  'P017', 'PC02', 40),
('SC0018', '2026-08-04T15:00:00', 80000,  'P018', 'PC03', 50),
('SC0019', '2026-08-04T09:00:00', 90000,  'P019', 'PC04', 40),
('SC0020', '2026-08-04T12:00:00', 100000, 'P020', 'PC05', 30);

INSERT INTO dbo.SuatChieu
    (Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa)
VALUES
('SC0021', '2026-08-05T15:00:00', 70000,  'P001', 'PC01', 30),
('SC0022', '2026-08-05T09:00:00', 80000,  'P002', 'PC02', 40),
('SC0023', '2026-08-05T12:00:00', 90000,  'P003', 'PC03', 50),
('SC0024', '2026-08-05T15:00:00', 100000, 'P004', 'PC04', 40),
('SC0025', '2026-08-05T09:00:00', 70000,  'P005', 'PC05', 30);

INSERT INTO dbo.SuatChieu
    (Ma, ThoiGian, GiaVe, MaPhim, MaPhongChieu, SoLuongGheToiDa)
VALUES
('SC0026', '2026-08-06T12:00:00', 80000,  'P006', 'PC01', 30),
('SC0027', '2026-08-06T15:00:00', 90000,  'P007', 'PC02', 40),
('SC0028', '2026-08-06T09:00:00', 100000, 'P008', 'PC03', 50),
('SC0029', '2026-08-06T12:00:00', 70000,  'P009', 'PC04', 40),
('SC0030', '2026-08-06T15:00:00', 80000,  'P010', 'PC05', 30);
GO

-- 3.5. Dữ liệu KhachHang
INSERT INTO dbo.KhachHang(Ma, HoTen, SDT, Email)
VALUES
('KH001', N'Nguyen Minh Anh',   '0900000001', 'minhanh01@example.com'),
('KH002', N'Tran Thu Ha',       '0900000002', 'thuha02@example.com'),
('KH003', N'Le Quang Huy',      '0900000003', 'quanghuy03@example.com'),
('KH004', N'Pham Ngoc Lan',     '0900000004', 'ngoclan04@example.com'),
('KH005', N'Hoang Gia Bao',     '0900000005', 'giabao05@example.com'),
('KH006', N'Vo Thanh Truc',     '0900000006', 'thanhtruc06@example.com'),
('KH007', N'Dang Duc Minh',     '0900000007', 'ducminh07@example.com'),
('KH008', N'Bui Khanh Linh',    '0900000008', 'khanhlinh08@example.com'),
('KH009', N'Do Tuan Kiet',      '0900000009', 'tuankiet09@example.com'),
('KH010', N'Ngo Phuong Thao',   '0900000010', 'phuongthao10@example.com'),
('KH011', N'Nguyen Hoai Nam',   '0900000011', 'hoainam11@example.com'),
('KH012', N'Tran My Duyen',     '0900000012', 'myduyen12@example.com'),
('KH013', N'Le Anh Tuan',       '0900000013', 'anhtuan13@example.com'),
('KH014', N'Pham Bao Chau',     '0900000014', 'baochau14@example.com'),
('KH015', N'Hoang Hai Yen',     '0900000015', 'haiyen15@example.com'),
('KH016', N'Vo Quoc Viet',      '0900000016', 'quocviet16@example.com'),
('KH017', N'Dang Thanh Ngan',   '0900000017', 'thanhngan17@example.com'),
('KH018', N'Bui Duc Long',      '0900000018', 'duclong18@example.com'),
('KH019', N'Do Ha My',          '0900000019', 'hamy19@example.com'),
('KH020', N'Ngo Tien Dat',      '0900000020', 'tiendat20@example.com'),
('KH021', N'Nguyen Ngoc Mai',   '0900000021', 'ngocmai21@example.com'),
('KH022', N'Tran Trung Hieu',   '0900000022', 'trunghieu22@example.com'),
('KH023', N'Le Bao Ngoc',       '0900000023', 'baongoc23@example.com'),
('KH024', N'Pham Quoc Anh',     '0900000024', 'quocanh24@example.com'),
('KH025', N'Hoang Thu Trang',   '0900000025', 'thutrang25@example.com');
GO

-- 3.6. Dữ liệu HoaDon
INSERT INTO dbo.HoaDon(Ma, NgayMua, MaKhachHang, SoTien)
VALUES
('HD0001', '2026-08-01T07:00:00', 'KH001', 140000),
('HD0002', '2026-08-01T10:00:00', 'KH002', 160000),
('HD0003', '2026-08-01T13:00:00', 'KH003', 180000),
('HD0004', '2026-08-01T07:00:00', 'KH004', 200000),
('HD0005', '2026-08-01T10:00:00', 'KH005', 140000),
('HD0006', '2026-08-02T13:00:00', 'KH006', 160000),
('HD0007', '2026-08-02T07:00:00', 'KH007', 180000),
('HD0008', '2026-08-02T10:00:00', 'KH008', 200000),
('HD0009', '2026-08-02T13:00:00', 'KH009', 140000),
('HD0010', '2026-08-02T07:00:00', 'KH010', 160000),
('HD0011', '2026-08-03T10:00:00', 'KH011', 180000),
('HD0012', '2026-08-03T13:00:00', 'KH012', 200000),
('HD0013', '2026-08-03T07:00:00', 'KH013', 140000),
('HD0014', '2026-08-03T10:00:00', 'KH014', 160000),
('HD0015', '2026-08-03T13:00:00', 'KH015', 180000),
('HD0016', '2026-08-04T07:00:00', 'KH016', 200000),
('HD0017', '2026-08-04T10:00:00', 'KH017', 140000),
('HD0018', '2026-08-04T13:00:00', 'KH018', 160000),
('HD0019', '2026-08-04T07:00:00', 'KH019', 180000),
('HD0020', '2026-08-04T10:00:00', 'KH020', 200000),
('HD0021', '2026-08-05T13:00:00', 'KH021', 140000),
('HD0022', '2026-08-05T07:00:00', 'KH022', 160000),
('HD0023', '2026-08-05T10:00:00', 'KH023', 180000),
('HD0024', '2026-08-05T13:00:00', 'KH024', 200000);
GO

-- 3.7. Dữ liệu Ve
INSERT INTO dbo.Ve(Ma, MaGhe, MaSuatChieu, MaHoaDon)
VALUES
('V0001', 'G01001', 'SC0001', 'HD0001'),
('V0002', 'G01002', 'SC0001', 'HD0001'),
('V0003', 'G02001', 'SC0002', 'HD0002'),
('V0004', 'G02002', 'SC0002', 'HD0002'),
('V0005', 'G03001', 'SC0003', 'HD0003'),
('V0006', 'G03002', 'SC0003', 'HD0003'),
('V0007', 'G04001', 'SC0004', 'HD0004'),
('V0008', 'G04002', 'SC0004', 'HD0004'),
('V0009', 'G05001', 'SC0005', 'HD0005'),
('V0010', 'G05002', 'SC0005', 'HD0005'),
('V0011', 'G01001', 'SC0006', 'HD0006'),
('V0012', 'G01002', 'SC0006', 'HD0006'),
('V0013', 'G02001', 'SC0007', 'HD0007'),
('V0014', 'G02002', 'SC0007', 'HD0007'),
('V0015', 'G03001', 'SC0008', 'HD0008'),
('V0016', 'G03002', 'SC0008', 'HD0008'),
('V0017', 'G04001', 'SC0009', 'HD0009'),
('V0018', 'G04002', 'SC0009', 'HD0009'),
('V0019', 'G05001', 'SC0010', 'HD0010'),
('V0020', 'G05002', 'SC0010', 'HD0010'),
('V0021', 'G01001', 'SC0011', 'HD0011'),
('V0022', 'G01002', 'SC0011', 'HD0011'),
('V0023', 'G02001', 'SC0012', 'HD0012'),
('V0024', 'G02002', 'SC0012', 'HD0012'),
('V0025', 'G03001', 'SC0013', 'HD0013'),
('V0026', 'G03002', 'SC0013', 'HD0013'),
('V0027', 'G04001', 'SC0014', 'HD0014'),
('V0028', 'G04002', 'SC0014', 'HD0014'),
('V0029', 'G05001', 'SC0015', 'HD0015'),
('V0030', 'G05002', 'SC0015', 'HD0015'),
('V0031', 'G01001', 'SC0016', 'HD0016'),
('V0032', 'G01002', 'SC0016', 'HD0016'),
('V0033', 'G02001', 'SC0017', 'HD0017'),
('V0034', 'G02002', 'SC0017', 'HD0017'),
('V0035', 'G03001', 'SC0018', 'HD0018'),
('V0036', 'G03002', 'SC0018', 'HD0018'),
('V0037', 'G04001', 'SC0019', 'HD0019'),
('V0038', 'G04002', 'SC0019', 'HD0019'),
('V0039', 'G05001', 'SC0020', 'HD0020'),
('V0040', 'G05002', 'SC0020', 'HD0020'),
('V0041', 'G01001', 'SC0021', 'HD0021'),
('V0042', 'G01002', 'SC0021', 'HD0021'),
('V0043', 'G02001', 'SC0022', 'HD0022'),
('V0044', 'G02002', 'SC0022', 'HD0022'),
('V0045', 'G03001', 'SC0023', 'HD0023'),
('V0046', 'G03002', 'SC0023', 'HD0023'),
('V0047', 'G04001', 'SC0024', 'HD0024'),
('V0048', 'G04002', 'SC0024', 'HD0024');
GO

-- 3.8. Dữ liệu ThanhToan
INSERT INTO dbo.ThanhToan(Ma, TrangThai, PhuongThuc, ThoiGian, MaHoaDon)
VALUES
('TTF001', 'That bai', 'The', '2026-08-01T07:05:00', 'HD0001'),
('TTF002', 'That bai', 'The', '2026-08-01T10:05:00', 'HD0002'),
('TTF003', 'That bai', 'The', '2026-08-01T13:05:00', 'HD0003'),
('TTF004', 'That bai', 'The', '2026-08-01T07:05:00', 'HD0004'),
('TTF005', 'That bai', 'The', '2026-08-01T10:05:00', 'HD0005'),
('TTF006', 'That bai', 'The', '2026-08-02T13:05:00', 'HD0006');
GO

INSERT INTO dbo.ThanhToan(Ma, TrangThai, PhuongThuc, ThoiGian, MaHoaDon)
VALUES
('TTS001', 'Thanh cong', 'Chuyen khoan', '2026-08-01T07:10:00', 'HD0001'),
('TTS002', 'Thanh cong', 'The',          '2026-08-01T10:10:00', 'HD0002'),
('TTS003', 'Thanh cong', 'Vi dien tu',   '2026-08-01T13:10:00', 'HD0003'),
('TTS004', 'Thanh cong', 'Tien mat',     '2026-08-01T07:10:00', 'HD0004'),
('TTS005', 'Thanh cong', 'Chuyen khoan', '2026-08-01T10:10:00', 'HD0005'),
('TTS006', 'Thanh cong', 'The',          '2026-08-02T13:10:00', 'HD0006'),
('TTS007', 'Thanh cong', 'Vi dien tu',   '2026-08-02T07:10:00', 'HD0007'),
('TTS008', 'Thanh cong', 'Tien mat',     '2026-08-02T10:10:00', 'HD0008'),
('TTS009', 'Thanh cong', 'Chuyen khoan', '2026-08-02T13:10:00', 'HD0009'),
('TTS010', 'Thanh cong', 'The',          '2026-08-02T07:10:00', 'HD0010'),
('TTS011', 'Thanh cong', 'Vi dien tu',   '2026-08-03T10:10:00', 'HD0011'),
('TTS012', 'Thanh cong', 'Tien mat',     '2026-08-03T13:10:00', 'HD0012'),
('TTS013', 'Thanh cong', 'Chuyen khoan', '2026-08-03T07:10:00', 'HD0013'),
('TTS014', 'Thanh cong', 'The',          '2026-08-03T10:10:00', 'HD0014'),
('TTS015', 'Thanh cong', 'Vi dien tu',   '2026-08-03T13:10:00', 'HD0015'),
('TTS016', 'Thanh cong', 'Tien mat',     '2026-08-04T07:10:00', 'HD0016'),
('TTS017', 'Thanh cong', 'Chuyen khoan', '2026-08-04T10:10:00', 'HD0017'),
('TTS018', 'Thanh cong', 'The',          '2026-08-04T13:10:00', 'HD0018'),
('TTS019', 'Thanh cong', 'Vi dien tu',   '2026-08-04T07:10:00', 'HD0019'),
('TTS020', 'Thanh cong', 'Tien mat',     '2026-08-04T10:10:00', 'HD0020'),
('TTS021', 'Thanh cong', 'Chuyen khoan', '2026-08-05T13:10:00', 'HD0021'),
('TTS022', 'Thanh cong', 'The',          '2026-08-05T07:10:00', 'HD0022'),
('TTS023', 'Thanh cong', 'Vi dien tu',   '2026-08-05T10:10:00', 'HD0023'),
('TTS024', 'Thanh cong', 'Tien mat',     '2026-08-05T13:10:00', 'HD0024');
GO

INSERT INTO dbo.ThanhToan(Ma, TrangThai, PhuongThuc, ThoiGian, MaHoaDon)
VALUES
('TTR005', 'Hoan tien', 'The',         '2026-08-02T10:00:00', 'HD0005'),
('TTR012', 'Hoan tien', 'Vi dien tu',  '2026-08-04T10:00:00', 'HD0012');
GO

/*=============================================================================
  PHAN 4. VIEW 
=============================================================================*/

-- View 1: Chi tiết đầy đủ của từng vé 
CREATE VIEW dbo.vw_ChiTietVe
AS
SELECT  v.Ma AS MaVe,
        hd.Ma AS MaHoaDon,
        hd.NgayMua,
        kh.Ma AS MaKhachHang,
        kh.HoTen,
        p.Ma AS MaPhim,
        p.Ten AS TenPhim,
        sc.Ma AS MaSuatChieu,
        sc.ThoiGian,
        pc.Ma AS MaPhongChieu,
        pc.Ten AS TenPhong,
        g.SoGhe,
        sc.GiaVe
FROM dbo.Ve AS v
JOIN dbo.HoaDon AS hd ON hd.Ma = v.MaHoaDon
JOIN dbo.KhachHang AS kh ON kh.Ma = hd.MaKhachHang
JOIN dbo.SuatChieu AS sc ON sc.Ma = v.MaSuatChieu
JOIN dbo.Phim AS p ON p.Ma = sc.MaPhim
JOIN dbo.PhongChieu AS pc ON pc.Ma = sc.MaPhongChieu
JOIN dbo.Ghe AS g ON g.Ma = v.MaGhe;
GO

-- CHẠY THỬ VIEW 1: xem chi tiết 10 vé đầu tiên.
SELECT TOP (10) * FROM dbo.vw_ChiTietVe ORDER BY MaVe;
GO

-- View 2: số ghế đã đặt, số ghế còn trống và tỷ lệ lấp đầy của từng suất chiếu.
CREATE VIEW dbo.vw_TinhTrangSuatChieu
AS
SELECT  sc.Ma AS MaSuatChieu,
        p.Ten AS TenPhim,
        pc.Ten AS TenPhong,
        sc.ThoiGian,
        sc.SoLuongGheToiDa,
        COUNT(v.Ma) AS SoGheDaDat,
        sc.SoLuongGheToiDa - COUNT(v.Ma) AS SoGheCon,
        CAST
        (
            100.0 * COUNT(v.Ma) / sc.SoLuongGheToiDa
            AS DECIMAL(5,2)
        ) AS TyLeLapDay
FROM dbo.SuatChieu AS sc
JOIN dbo.Phim AS p ON p.Ma = sc.MaPhim
JOIN dbo.PhongChieu AS pc ON pc.Ma = sc.MaPhongChieu
LEFT JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
GROUP BY sc.Ma, p.Ten, pc.Ten, sc.ThoiGian, sc.SoLuongGheToiDa;
GO

-- CHẠY THỬ VIEW 2: xem tình trạng đặt ghế của các suất chiếu.
SELECT TOP (10) *
FROM dbo.vw_TinhTrangSuatChieu
ORDER BY ThoiGian;
GO

-- View 3: Lịch sử thanh toán của từng hóa đơn, bao gồm trạng thái, phương thức và thời gian thanh toán.
CREATE VIEW dbo.vw_LichSuThanhToanHoaDon
AS
SELECT  tt.Ma AS MaThanhToan,
        tt.MaHoaDon,
        hd.NgayMua,
        kh.Ma AS MaKhachHang,
        kh.HoTen,
        hd.SoTien,
        tt.TrangThai,
        tt.PhuongThuc,
        tt.ThoiGian
FROM dbo.ThanhToan AS tt
JOIN dbo.HoaDon AS hd ON hd.Ma = tt.MaHoaDon
JOIN dbo.KhachHang AS kh ON kh.Ma = hd.MaKhachHang;
GO

-- CHẠY THỬ VIEW 3: xem 15 lần thanh toán đầu tiên.
SELECT TOP (15) *
FROM dbo.vw_LichSuThanhToanHoaDon
ORDER BY MaHoaDon, ThoiGian;
GO

/*=============================================================================
  PHAN 5. FUNCTION 
=============================================================================*/

-- Function 1: Đếm số ghế đã đặt của một suất chiếu cụ thể.
CREATE FUNCTION dbo.fn_DemSoVeSuatChieu
(
    @MaSuatChieu VARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @SoVe INT;

    SELECT @SoVe = COUNT(*)
    FROM dbo.Ve
    WHERE MaSuatChieu = @MaSuatChieu;

    RETURN ISNULL(@SoVe, 0);
END;
GO

-- CHẠY THỬ FUNCTION 1: suất SC0001 có 2 vé đã đặt.
SELECT dbo.fn_DemSoVeSuatChieu('SC0001') AS SoVe_SC0001;
GO

-- Function 2 :Tính lại tổng tiền của một hóa đơn dựa trên các vé đã được đặt.
CREATE FUNCTION dbo.fn_TinhTongTienHoaDon
(
    @MaHoaDon VARCHAR(50)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18,2);

    SELECT @TongTien = SUM(GiaVe)
    FROM dbo.vw_ChiTietVe
    WHERE MaHoaDon = @MaHoaDon;

    RETURN ISNULL(@TongTien, 0);
END;
GO

-- CHẠY THỬ FUNCTION 2: hóa đơn HD0001 có tổng tiền 140.000 đồng.
SELECT dbo.fn_TinhTongTienHoaDon('HD0001') AS TongTien_HD0001;
GO

-- Function 3 : Hàm bảng trả về lịch sử mua vé của một khách hàng.
CREATE FUNCTION dbo.fn_LichSuMuaVeKhachHang
(
    @MaKhachHang VARCHAR(50)
)
RETURNS TABLE
AS
RETURN
(
    SELECT MaHoaDon, NgayMua, MaVe, TenPhim,
           ThoiGian, TenPhong, SoGhe, GiaVe
    FROM dbo.vw_ChiTietVe
    WHERE MaKhachHang = @MaKhachHang
);
GO

-- CHẠY THỬ FUNCTION 3: xem lịch sử mua vé của khách hàng KH001.
SELECT *
FROM dbo.fn_LichSuMuaVeKhachHang('KH001')
ORDER BY NgayMua DESC, MaVe;
GO

/*=============================================================================
  PHAN 6. STORED PROCEDURE 
=============================================================================*/

-- Procedure 1 : Tìm suất chiếu theo ngày, có thể lọc theo phim và phòng chiếu.
CREATE PROCEDURE dbo.sp_TimSuatChieuTheoNgay
    @Ngay       DATE,
    @MaPhim     VARCHAR(50) = NULL,
    @MaPhong    VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  sc.Ma AS MaSuatChieu,
            p.Ten AS TenPhim,
            pc.Ten AS TenPhong,
            sc.ThoiGian,
            sc.GiaVe,
            sc.SoLuongGheToiDa
                - dbo.fn_DemSoVeSuatChieu(sc.Ma) AS SoGheCon
    FROM dbo.SuatChieu AS sc
    JOIN dbo.Phim AS p ON p.Ma = sc.MaPhim
    JOIN dbo.PhongChieu AS pc ON pc.Ma = sc.MaPhongChieu
    WHERE CAST(sc.ThoiGian AS DATE) = @Ngay
      AND (@MaPhim IS NULL OR sc.MaPhim = @MaPhim)
      AND (@MaPhong IS NULL OR sc.MaPhongChieu = @MaPhong)
    ORDER BY sc.ThoiGian;
END;
GO

-- CHẠY THỬ PROCEDURE 1: tìm các suất ngày 01/08/2026 tại phòng PC01.
EXEC dbo.sp_TimSuatChieuTheoNgay
    @Ngay = '2026-08-01',
    @MaPhim = NULL,
    @MaPhong = 'PC01';
GO

-- Procedure 2 : Đặt vé cho một khách hàng, tạo hóa đơn nếu chưa tồn tại.
CREATE PROCEDURE dbo.sp_DatVe
    @MaHoaDon       VARCHAR(50),
    @MaKhachHang    VARCHAR(50),
    @MaVe           VARCHAR(50),
    @MaSuatChieu    VARCHAR(50),
    @MaGhe          VARCHAR(50),
    @NgayMua        DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @GiaVe DECIMAL(18,2);

        SELECT @GiaVe = GiaVe
        FROM dbo.SuatChieu
        WHERE Ma = @MaSuatChieu;

        IF @GiaVe IS NULL
            RAISERROR(N'Suat chieu khong ton tai.', 16, 1);

        IF EXISTS
        (
            SELECT 1 FROM dbo.HoaDon
            WHERE Ma = @MaHoaDon
              AND MaKhachHang <> @MaKhachHang
        )
            RAISERROR(N'Hoa don khong thuoc khach hang nay.', 16, 1);

        IF EXISTS
        (
            SELECT 1 FROM dbo.ThanhToan
            WHERE MaHoaDon = @MaHoaDon
              AND TrangThai = 'Thanh cong'
        )
            RAISERROR(N'Hoa don da thanh toan.', 16, 1);

        IF NOT EXISTS (SELECT 1 FROM dbo.HoaDon WHERE Ma = @MaHoaDon)
        BEGIN
            INSERT INTO dbo.HoaDon(Ma, NgayMua, MaKhachHang, SoTien)
            VALUES (@MaHoaDon, ISNULL(@NgayMua, SYSDATETIME()),
                    @MaKhachHang, @GiaVe);
        END;

        INSERT INTO dbo.Ve(Ma, MaGhe, MaSuatChieu, MaHoaDon)
        VALUES (@MaVe, @MaGhe, @MaSuatChieu, @MaHoaDon);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @ThongBaoLoi NVARCHAR(4000);
        SET @ThongBaoLoi = ERROR_MESSAGE();
        RAISERROR(@ThongBaoLoi, 16, 1);
        RETURN;
    END CATCH;
END;
GO

-- CHẠY THỬ PROCEDURE 2: đặt một vé, sau đó ROLLBACK.
BEGIN TRY
    BEGIN TRANSACTION;

    EXEC dbo.sp_DatVe
        @MaHoaDon = 'HDTEST1',
        @MaKhachHang = 'KH025',
        @MaVe = 'VTEST1',
        @MaSuatChieu = 'SC0030',
        @MaGhe = 'G05003',
        @NgayMua = '2026-08-06T12:00:00';

    SELECT hd.Ma, hd.NgayMua, hd.MaKhachHang, hd.SoTien,
           v.Ma AS MaVe, v.MaSuatChieu, v.MaGhe
    FROM dbo.HoaDon AS hd
    JOIN dbo.Ve AS v ON v.MaHoaDon = hd.Ma
    WHERE hd.Ma = 'HDTEST1';

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE() AS LoiKiemThuDatVe;
END CATCH;
GO

-- Procedure 3 :Ghi một bản ghi vào lịch sử thanh toán của một hóa đơn, kiểm tra trạng thái và thời gian hợp lệ.
CREATE PROCEDURE dbo.sp_GhiNhanThanhToan
    @MaThanhToan VARCHAR(50),
    @MaHoaDon    VARCHAR(50),
    @TrangThai   VARCHAR(20),
    @PhuongThuc  VARCHAR(30),
    @ThoiGian    DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.HoaDon WHERE Ma = @MaHoaDon)
    BEGIN
        RAISERROR(N'Hoa don khong ton tai.', 16, 1);
        RETURN;
    END;

    SET @ThoiGian = ISNULL(@ThoiGian, SYSDATETIME());

    IF @ThoiGian < (SELECT NgayMua FROM dbo.HoaDon WHERE Ma = @MaHoaDon)
    BEGIN
        RAISERROR(N'Thoi gian thanh toan khong duoc truoc ngay mua.', 16, 1);
        RETURN;
    END;

    IF @TrangThai = 'Hoan tien'
       AND NOT EXISTS
           (SELECT 1 FROM dbo.ThanhToan
            WHERE MaHoaDon = @MaHoaDon AND TrangThai = 'Thanh cong')
    BEGIN
        RAISERROR(N'Hoa don chua thanh toan nen khong the hoan tien.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.ThanhToan(Ma, TrangThai, PhuongThuc, ThoiGian, MaHoaDon)
    VALUES
    (
        @MaThanhToan,
        @TrangThai,
        @PhuongThuc,
        @ThoiGian,
        @MaHoaDon
    );
END;
GO

-- CHẠY THỬ PROCEDURE 3: tạo hóa đơn, thanh toán rồi ROLLBACK.
BEGIN TRY
    BEGIN TRANSACTION;

    EXEC dbo.sp_DatVe
        @MaHoaDon = 'HDTEST1',
        @MaKhachHang = 'KH025',
        @MaVe = 'VTEST1',
        @MaSuatChieu = 'SC0030',
        @MaGhe = 'G05003',
        @NgayMua = '2026-08-06T12:00:00';

    EXEC dbo.sp_GhiNhanThanhToan
        @MaThanhToan = 'TTTEST1',
        @MaHoaDon = 'HDTEST1',
        @TrangThai = 'Thanh cong',
        @PhuongThuc = 'Chuyen khoan',
        @ThoiGian = '2026-08-06T12:05:00';

    SELECT hd.Ma AS MaHoaDon, hd.SoTien,
           tt.Ma AS MaThanhToan, tt.TrangThai,
           tt.PhuongThuc, tt.ThoiGian
    FROM dbo.HoaDon AS hd
    JOIN dbo.ThanhToan AS tt ON tt.MaHoaDon = hd.Ma
    WHERE hd.Ma = 'HDTEST1';

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE() AS LoiKiemThuThanhToan;
END CATCH;
GO

/*=============================================================================
  PHAN 7. TRUY VẤN CƠ BẢN PHỔ BIẾN
=============================================================================*/

-- 7.1. Tra cuu phim theo ten, the loai hoac khoang thoi luong.
DECLARE @TuKhoaPhim NVARCHAR(200) = N'Mua',
        @TheLoai NVARCHAR(100) = NULL,
        @ThoiLuongTu INT = 90,
        @ThoiLuongDen INT = 130;

SELECT Ma, Ten, TheLoai, ThoiLuong
FROM dbo.Phim
WHERE (@TuKhoaPhim IS NULL OR Ten LIKE N'%' + @TuKhoaPhim + N'%')
  AND (@TheLoai IS NULL OR TheLoai = @TheLoai)
  AND ThoiLuong BETWEEN @ThoiLuongTu AND @ThoiLuongDen
ORDER BY Ten;
GO

-- 7.2. Tra cuu lich chieu cua mot bo phim.
DECLARE @MaPhimCanTim VARCHAR(50) = 'P001';

SELECT p.Ten, sc.Ma AS MaSuatChieu, sc.ThoiGian,
       pc.Ten AS TenPhong, sc.GiaVe
FROM dbo.Phim AS p
JOIN dbo.SuatChieu AS sc ON sc.MaPhim = p.Ma
JOIN dbo.PhongChieu AS pc ON pc.Ma = sc.MaPhongChieu
WHERE p.Ma = @MaPhimCanTim
ORDER BY sc.ThoiGian;
GO

-- 7.3. Tra cuu suat chieu theo ngay, phong va khoang thoi gian.
DECLARE @TuThoiGian DATETIME2(0) = '2026-08-01T00:00:00',
        @DenThoiGian DATETIME2(0) = '2026-08-04T23:59:59',
        @PhongCanTim VARCHAR(50) = 'PC01';

SELECT sc.Ma, p.Ten AS TenPhim, pc.Ten AS TenPhong,
       sc.ThoiGian, sc.GiaVe
FROM dbo.SuatChieu AS sc
JOIN dbo.Phim AS p ON p.Ma = sc.MaPhim
JOIN dbo.PhongChieu AS pc ON pc.Ma = sc.MaPhongChieu
WHERE sc.ThoiGian BETWEEN @TuThoiGian AND @DenThoiGian
  AND (@PhongCanTim IS NULL OR sc.MaPhongChieu = @PhongCanTim)
ORDER BY sc.ThoiGian;
GO

-- 7.4. Tim khach hang theo ten hoac so dien thoai.
DECLARE @TuKhoaKhachHang NVARCHAR(100) = N'Minh';

SELECT Ma, HoTen, SDT, Email
FROM dbo.KhachHang
WHERE HoTen LIKE N'%' + @TuKhoaKhachHang + N'%'
   OR SDT LIKE '%' + CONVERT(VARCHAR(100), @TuKhoaKhachHang) + '%'
ORDER BY HoTen;
GO

-- 7.5. Tra cuu lich su mua ve cua mot khach hang.
SELECT *
FROM dbo.fn_LichSuMuaVeKhachHang('KH001')
ORDER BY NgayMua DESC, MaVe;
GO

/*=============================================================================
  PHAN 8. TRUY VAN THONG KE
=============================================================================*/

-- 8.1. Theo doi so ghe da dat, so ghe con va ty le lap day cua tung suat.
SELECT *
FROM dbo.vw_TinhTrangSuatChieu
ORDER BY ThoiGian, TenPhong;
GO

-- 8.2. Liet ke phim khong co ve ban trong mot thang.
DECLARE @DauThang DATE = '2026-08-01';
DECLARE @DauThangSau DATE = DATEADD(MONTH, 1, @DauThang);

SELECT p.Ma, p.Ten, p.TheLoai
FROM dbo.Phim AS p
WHERE p.Ma NOT IN
(
    SELECT sc.MaPhim
    FROM dbo.SuatChieu AS sc
    JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
    JOIN dbo.HoaDon AS hd ON hd.Ma = v.MaHoaDon
    WHERE hd.NgayMua >= @DauThang
      AND hd.NgayMua < @DauThangSau
)
ORDER BY p.Ten;
GO

-- 8.3. So khach hang mua ve thanh cong trong mot khoang thoi gian.
DECLARE @TuNgayKH DATETIME2(0) = '2026-08-01T00:00:00',
        @DenNgayKH DATETIME2(0) = '2026-08-31T23:59:59';

SELECT COUNT(DISTINCT hd.MaKhachHang) AS SoKhachHangMuaVe
FROM dbo.HoaDon AS hd
JOIN dbo.ThanhToan AS tc
  ON tc.MaHoaDon = hd.Ma
 AND tc.TrangThai = 'Thanh cong'
LEFT JOIN dbo.ThanhToan AS ht
  ON ht.MaHoaDon = hd.Ma
 AND ht.TrangThai = 'Hoan tien'
WHERE hd.NgayMua BETWEEN @TuNgayKH AND @DenNgayKH
  AND ht.Ma IS NULL;
GO

/*=============================================================================
  PHAN 9. TRUY VAN NHOM (GROUP BY)
=============================================================================*/

-- 9.1. Thong ke so ve ban ra theo tung phim.
SELECT p.Ma, p.Ten, COUNT(v.Ma) AS SoVeDaBan
FROM dbo.Phim AS p
LEFT JOIN dbo.SuatChieu AS sc ON sc.MaPhim = p.Ma
LEFT JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
GROUP BY p.Ma, p.Ten
ORDER BY SoVeDaBan DESC, p.Ten;
GO

-- 9.2. Thong ke so ve ban ra theo tung suat chieu.
SELECT sc.Ma, p.Ten AS TenPhim, sc.ThoiGian,
       COUNT(v.Ma) AS SoVeDaBan
FROM dbo.SuatChieu AS sc
JOIN dbo.Phim AS p ON p.Ma = sc.MaPhim
LEFT JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
GROUP BY sc.Ma, p.Ten, sc.ThoiGian
ORDER BY SoVeDaBan DESC, sc.ThoiGian;
GO

-- 9.3. Thong ke so ve ban ra theo tung phong chieu.
SELECT pc.Ma, pc.Ten, COUNT(v.Ma) AS SoVeDaBan
FROM dbo.PhongChieu AS pc
LEFT JOIN dbo.SuatChieu AS sc ON sc.MaPhongChieu = pc.Ma
LEFT JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
GROUP BY pc.Ma, pc.Ten
ORDER BY SoVeDaBan DESC, pc.Ten;
GO

/*=============================================================================
  PHAN 10. TRUY VAN TONG HOP
=============================================================================*/

-- 10.1. Doanh thu thuan theo nam va thang thanh toan thanh cong.
SELECT YEAR(tc.ThoiGian) AS Nam,
       MONTH(tc.ThoiGian) AS Thang,
       COUNT(*) AS SoHoaDon,
       SUM(hd.SoTien) AS DoanhThuThuan
FROM dbo.HoaDon AS hd
JOIN dbo.ThanhToan AS tc
  ON tc.MaHoaDon = hd.Ma
 AND tc.TrangThai = 'Thanh cong'
LEFT JOIN dbo.ThanhToan AS ht
  ON ht.MaHoaDon = hd.Ma
 AND ht.TrangThai = 'Hoan tien'
WHERE ht.Ma IS NULL
GROUP BY YEAR(tc.ThoiGian), MONTH(tc.ThoiGian)
ORDER BY Nam, Thang;
GO

-- 10.2. Tim phim co doanh thu cao nhat va thap nhat.
SELECT TOP (1) N'Cao nhat' AS XepLoai,
       p.Ma, p.Ten, SUM(sc.GiaVe) AS DoanhThu
FROM dbo.Phim AS p
JOIN dbo.SuatChieu AS sc ON sc.MaPhim = p.Ma
JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
JOIN dbo.ThanhToan AS tc
  ON tc.MaHoaDon = v.MaHoaDon
 AND tc.TrangThai = 'Thanh cong'
LEFT JOIN dbo.ThanhToan AS ht
  ON ht.MaHoaDon = v.MaHoaDon
 AND ht.TrangThai = 'Hoan tien'
WHERE ht.Ma IS NULL
GROUP BY p.Ma, p.Ten
ORDER BY DoanhThu DESC;

SELECT TOP (1) N'Thap nhat' AS XepLoai,
       p.Ma, p.Ten, SUM(sc.GiaVe) AS DoanhThu
FROM dbo.Phim AS p
JOIN dbo.SuatChieu AS sc ON sc.MaPhim = p.Ma
JOIN dbo.Ve AS v ON v.MaSuatChieu = sc.Ma
JOIN dbo.ThanhToan AS tc
  ON tc.MaHoaDon = v.MaHoaDon
 AND tc.TrangThai = 'Thanh cong'
LEFT JOIN dbo.ThanhToan AS ht
  ON ht.MaHoaDon = v.MaHoaDon
 AND ht.TrangThai = 'Hoan tien'
WHERE ht.Ma IS NULL
GROUP BY p.Ma, p.Ten
ORDER BY DoanhThu ASC;
GO

-- 10.3. Bao cao kinh doanh tong hop theo thang/nam.
SELECT YEAR(tc.ThoiGian) AS Nam, MONTH(tc.ThoiGian) AS Thang, COUNT(hd.Ma) AS TongHoaDon, COUNT(DISTINCT hd.MaKhachHang) AS SoKhachHang, SUM(hd.SoTien) AS TongDoanhThu, CAST(AVG(hd.SoTien) AS DECIMAL(18,2)) AS HoaDonTrungBinh FROM dbo.HoaDon AS hd JOIN dbo.ThanhToan AS tc ON tc.MaHoaDon = hd.Ma AND tc.TrangThai = 'Thanh cong' LEFT JOIN dbo.ThanhToan AS ht ON ht.MaHoaDon = hd.Ma AND ht.TrangThai = 'Hoan tien' WHERE ht.Ma IS NULL GROUP BY YEAR(tc.ThoiGian), MONTH(tc.ThoiGian) ORDER BY Nam, Thang;
GO
