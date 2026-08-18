import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/mouvement.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'rapport_service.dart';

/// Génère les trois rapports PDF demandés :
/// - Liste des entrées / mois
/// - Liste des sorties / mois
/// - Balance du mois / de l'année
class PdfService {
  Future<pw.ImageProvider?> _chargerLogo() async {
    try {
      final logoBytes = await rootBundle.load(AppConstants.logoAssetPath);
      return pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> genererListeMouvements({
    required List<Mouvement> mouvements,
    required String titre,
    required int annee,
    required int mois,
    required String nomEntreprise,
    required String devise,
  }) async {
    final doc = pw.Document();
    final total = mouvements.fold<double>(0, (s, m) => s + m.montant);
    final logoImage = await _chargerLogo();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _entete(nomEntreprise, titre, logo: logoImage),
        footer: (context) => _piedDePage(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text(
            'Période : ${moisFrancais[mois - 1]} $annee',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _tableauMouvements(mouvements, devise),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total : ${CurrencyFormatter.formatMontant(total, devise: devise)}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<Uint8List> genererBalance({
    required Balance balance,
    required String nomEntreprise,
    required String devise,
    required int annee,
    int? mois,
  }) async {
    final doc = pw.Document();
    final estMensuelle = mois != null;
    final periode = estMensuelle ? '${moisFrancais[mois! - 1]} $annee' : 'Année $annee';
    final titre = estMensuelle ? 'Balance du mois' : "Balance de l'année";
    final logoImage = await _chargerLogo();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _entete(nomEntreprise, titre, logo: logoImage),
            pw.SizedBox(height: 8),
            pw.Text(
              'Période : $periode',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                _ligneBalance('Total des entrées',
                    CurrencyFormatter.formatMontant(balance.totalEntrees, devise: devise)),
                _ligneBalance('Total des sorties',
                    CurrencyFormatter.formatMontant(balance.totalSorties, devise: devise)),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: balance.solde >= 0 ? PdfColors.green50 : PdfColors.red50,
                border: pw.Border.all(
                  color: balance.solde >= 0 ? PdfColors.green : PdfColors.red,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SOLDE (Balance)',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    CurrencyFormatter.formatMontant(balance.solde, devise: devise),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            _piedDePage(context),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _entete(String nomEntreprise, String titre, {pw.ImageProvider? logo}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  nomEntreprise,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  titre,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
            if (logo != null)
              pw.Container(
                height: 55,
                width: 120,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1.5, color: PdfColors.blue900),
      ],
    );
  }

  pw.Widget _piedDePage(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Généré le ${CurrencyFormatter.formatDateHeure(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.TableRow _ligneBalance(String libelle, String valeur) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(libelle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(valeur, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  pw.Widget _tableauMouvements(List<Mouvement> mouvements, String devise) {
    final entetes = ['Date', 'Catégorie', 'Description', 'Mode', 'Montant'];

    return pw.TableHelper.fromTextArray(
      headers: entetes,
      data: mouvements.map((m) {
        return [
          CurrencyFormatter.formatDate(m.date),
          m.categorieNom ?? '-',
          m.description,
          modesPaiementLabels[m.modePaiement] ?? m.modePaiement,
          CurrencyFormatter.formatMontant(m.montant, devise: devise),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {4: pw.Alignment.centerRight},
      cellHeight: 22,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    );
  }
}
