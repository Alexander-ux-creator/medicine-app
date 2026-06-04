import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<String?> searchDescription(String query) async {
    try {
      final isConnected = await _checkInternetConnection();
      if (!isConnected) {
        return null;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final wikiResult = await _searchWikipedia(query);
      if (wikiResult != null) {
        return wikiResult;
      }

      final fdaResult = await _searchOpenFDA(query);
      if (fdaResult != null) {
        return fdaResult;
      }

      final localResult = _searchLocalDatabase(query);
      if (localResult != null) {
        return localResult;
      }

      return null;

    } catch (e) {
      return null;
    }
  }

  static Future<String?> _searchWikipedia(String query) async {
    try {
      final lang = query.contains(RegExp(r'[а-яА-ЯёЁ]')) ? 'ru' : 'en';
      
      final url = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchResults = data['query']['search'];

        if (searchResults != null && searchResults.isNotEmpty) {
          final title = searchResults[0]['title'];
          
          final extractUrl = Uri.parse(
            'https://$lang.wikipedia.org/w/api.php?action=query&prop=extracts&exintro=true&explaintext=true&titles=${Uri.encodeComponent(title)}&format=json'
          );

          final extractResponse = await http.get(extractUrl).timeout(const Duration(seconds: 5));

          if (extractResponse.statusCode == 200) {
            final extractData = json.decode(extractResponse.body);
            final pages = extractData['query']['pages'];
            final pageId = pages.keys.first;
            
            if (pageId != '-1') {
              String extract = pages[pageId]['extract'] ?? '';
              
              extract = extract.replaceAll(RegExp(r'\n+'), ' ').trim();
              if (extract.length > 200) {
                extract = '${extract.substring(0, 200)}...';
              }
              
              if (extract.isNotEmpty) {
                return extract;
              }
            }
          }
        }
      }
    } catch (e) {
      // Ошибка
    }
    return null;
  }

  static Future<String?> _searchOpenFDA(String query) async {
    try {
      final url = Uri.parse(
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:"${Uri.encodeComponent(query)}"&limit=1'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];

        if (results != null && results.isNotEmpty) {
          final purpose = results[0]['purpose'] ?? [];
          final indications = results[0]['indications_and_usage'] ?? [];
          
          String description = '';
          
          if (purpose.isNotEmpty) {
            description = '$description Назначение: ${purpose[0]}. ';
          }
          
          if (indications.isNotEmpty) {
            description = '$description Показания: ${indications[0]}';
          }

          if (description.isNotEmpty) {
            description = description.replaceAll(RegExp(r'<[^>]*>'), ' ');
            description = description.replaceAll(RegExp(r'\n+'), ' ').trim();
            
            if (description.length > 200) {
              description = '${description.substring(0, 200)}...';
            }
            
            return description;
          }
        }
      }
    } catch (e) {
      // Ошибка
    }
    return null;
  }

  static String? _searchLocalDatabase(String query) {
    final localMedicines = {
      'аспирин': 'Обезболивающее и жаропонижающее средство.',
      'парацетамол': 'Жаропонижающее и обезболивающее средство.',
      'ибупрофен': 'Противовоспалительное, обезболивающее средство.',
      'но-шпа': 'Спазмолитическое средство.',
      'супрастин': 'Антигистаминное средство от аллергии.',
      'активированный уголь': 'Сорбент при отравлениях.',
    };

    final queryLower = query.toLowerCase();
    
    for (final entry in localMedicines.entries) {
      if (queryLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static Future<bool> _checkInternetConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, String>?> searchByBarcode(String barcode) async {
    try {
      final isConnected = await _checkInternetConnection();
      if (!isConnected) {
        return null;
      }

      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 1) {
          final product = data['product'];
          
          return {
            'name': product['product_name'] ?? 'Неизвестное лекарство',
            'description': product['generic_name'] ?? 'Нет описания',
            'barcode': barcode,
          };
        }
      }
    } catch (e) {
      // Ошибка
    }

    return null;
  }
}