import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatMontant(double montant, {String devise = 'FCFA'}) {
    final format = NumberFormat.decimalPattern('fr_FR');
    return '${format.format(montant)} $devise';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatDateHeure(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }
}
