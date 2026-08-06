import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/omdb_item.dart';

class OMDbService {
  static const String _baseUrl = 'http://www.omdbapi.com/';
  static const String _apiKey = '2847abb2'; 

  Future<OMDbItem?> getByImdbId(String imdbId) async {
    final url = Uri.parse('$_baseUrl?apikey=$_apiKey&i=$imdbId&plot=full');
    final response = await http.get(url);

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data['Response'] == 'False') return null;

    return OMDbItem.fromJson(data);
  }

  Future<OMDbItem?> getByTitle(String title, {String? year}) async {
    final yearParam = year != null ? '&y=$year' : '';
    final url = Uri.parse('$_baseUrl?apikey=$_apiKey&t=${Uri.encodeComponent(title)}$yearParam');
    final response = await http.get(url);

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data['Response'] == 'False') return null;

    return OMDbItem.fromJson(data);
  }

  Future<List<OMDbItem>> search(String query, {String? type}) async {
    final typeParam = type != null ? '&type=$type' : '';
    final url = Uri.parse('$_baseUrl?apikey=$_apiKey&s=${Uri.encodeComponent(query)}$typeParam');
    final response = await http.get(url);

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data['Response'] == 'False') return [];

    final results = data['Search'] as List;
    return results.map((item) => OMDbItem.fromJson(item)).toList();
  }
}
