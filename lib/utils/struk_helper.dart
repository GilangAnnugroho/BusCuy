import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'currency_format.dart'; 
import 'date_format.dart';

class StrukHelper {
  static Future<void> cetakStruk(Map<String, dynamic> data) async {
    final doc = pw.Document();

    // 1. LOAD LOGO
    final logoProvider = await imageFromAssetBundle('assets/images/logo.png');

    // 2. CONFIG WARNA (Sesuai brand BusCuy)
    final PdfColor primaryColor = PdfColor.fromInt(0xFF1565C0); 
    final PdfColor secondaryColor = PdfColor.fromInt(0xFFF5F9FF); 
    final PdfColor accentColor = PdfColor.fromInt(0xFFFFA000);   
    final PdfColor textBlack = PdfColor.fromInt(0xFF000000); 
    final PdfColor textGrey = PdfColor.fromInt(0xFF424242); 

    final String tglCetak = DateHelper.formatWithTime(DateTime.now().toIso8601String());
    final bool isLunas = (data['sisa_bayar'] ?? 0) <= 0;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20), // Margin luar kecil agar full frame
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                // --- HEADER SECTION ---
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(25),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(height: 60, child: pw.Image(logoProvider)),
                          pw.SizedBox(height: 10),
                          pw.Text("BusCuy Official", 
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("INVOICE", 
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 35, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
                          pw.Text("NO: TRX-${data['id_transaksi'] ?? '-'}", 
                            style: pw.TextStyle(color: accentColor, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          pw.Text("Dicetak: $tglCetak", style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- CONTENT SECTION ---
                // Menggunakan Padding tetap, bukan Expanded agar tidak hilang jika data sedikit
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: pw.Column(
                    children: [
                      // Baris Data Penyewa & Unit
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: _buildSectionGroup("DATA PENYEWA", [
                              _buildItem("Nama Lengkap", data['nama_lengkap'] ?? 'Guest', textBlack, isBig: true),
                              _buildItem("Nomor HP", data['no_hp'] ?? '-', textBlack),
                              _buildItem("Alamat", data['alamat'] ?? '-', textBlack),
                            ], primaryColor),
                          ),
                          pw.SizedBox(width: 30),
                          pw.Expanded(
                            child: _buildSectionGroup("DETAIL UNIT", [
                              _buildItem("Unit Bus", data['nama_bus'] ?? '-', textBlack, isBig: true),
                              _buildItem("Plat Nomor", data['plat_nomor'] ?? '-', textBlack),
                              _buildItem("Kapasitas", "${data['kapasitas'] ?? '-'} Seat", textBlack),
                            ], primaryColor),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 40),

                      // Box Tanggal (Modern)
                      pw.Container(
                        padding: const pw.EdgeInsets.all(20),
                        decoration: pw.BoxDecoration(
                          color: secondaryColor,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: primaryColor, width: 1),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            _buildDateColumn("TANGGAL MULAI", DateHelper.formatShort(data['tgl_sewa']), primaryColor),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(20)),
                              child: pw.Text("${data['total_hari'] ?? '0'} HARI", style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            ),
                            _buildDateColumn("TANGGAL SELESAI", DateHelper.formatShort(data['tgl_kembali']), primaryColor),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 40),

                      // Rincian Biaya
                      pw.Divider(color: PdfColors.grey400, thickness: 1),
                      _buildFinanceRow("Total Biaya Sewa", CurrencyFormat.convertToIdr(data['total_biaya'], 0), textBlack, fontSize: 16),
                      _buildFinanceRow("Uang Muka (DP)", "- ${CurrencyFormat.convertToIdr(data['dp_bayar'], 0)}", PdfColors.red700, fontSize: 16),
                      pw.Divider(color: PdfColors.grey400, thickness: 1),
                      
                      pw.SizedBox(height: 25),

                      // Sisa Tagihan & Status Lunas
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("SISA TAGIHAN", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textGrey)),
                              pw.Text(
                                CurrencyFormat.convertToIdr(data['sisa_bayar'], 0),
                                style: pw.TextStyle(fontSize: 35, fontWeight: pw.FontWeight.bold, color: isLunas ? PdfColors.green800 : PdfColors.red800)
                              ),
                            ]
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: isLunas ? PdfColors.green800 : PdfColors.red800, width: 3),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text(
                              isLunas ? "LUNAS" : "PENDING",
                              style: pw.TextStyle(color: isLunas ? PdfColors.green800 : PdfColors.red800, fontSize: 24, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Spacer untuk memaksa footer ke bawah
                pw.Expanded(child: pw.SizedBox()), 

                // --- FOOTER SECTION ---
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.vertical(bottom: pw.Radius.circular(7)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Syarat & Ketentuan:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textBlack)),
                          pw.Text("1. Struk ini adalah bukti pembayaran yang sah.", style: pw.TextStyle(fontSize: 9, color: textBlack)),
                          pw.Text("2. Harap datang 30 menit sebelum jadwal sewa.", style: pw.TextStyle(fontSize: 9, color: textBlack)),
                        ],
                      ),
                      pw.BarcodeWidget(
                        data: "TRX-${data['id_transaksi'] ?? '0'}",
                        barcode: pw.Barcode.code128(),
                        width: 120,
                        height: 40,
                        drawText: false,
                        color: textBlack,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice-${data['id_transaksi']}',
    );
  }

  // --- HELPER WIDGETS ---

  static pw.Widget _buildSectionGroup(String title, List<pw.Widget> items, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(color: color, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
        pw.SizedBox(height: 5),
        pw.Container(height: 2, width: 30, color: color),
        pw.SizedBox(height: 12),
        ...items,
      ],
    );
  }

  static pw.Widget _buildItem(String label, String value, PdfColor textColor, {bool isBig = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: isBig ? 18 : 13, fontWeight: isBig ? pw.FontWeight.bold : pw.FontWeight.normal, color: textColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildDateColumn(String label, String date, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 5),
        pw.Text(date, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildFinanceRow(String label, String value, PdfColor textColor, {PdfColor? color, double fontSize = 12}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, color: textColor)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color ?? textColor)),
        ],
      ),
    );
  }
}