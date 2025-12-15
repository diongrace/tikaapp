import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/product_model.dart';

class ProductService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 1. Lister tous les produits (avec filtres)
  static Future<Map<String, dynamic>> getProducts({
    int? shopId,
    int? categoryId,
    String? search,
    bool? inStock,
    String? sortBy,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      if (shopId != null) 'shop_id': shopId.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (search != null) 'search': search,
      if (inStock != null) 'in_stock': inStock.toString(),
      if (sortBy != null) 'sort_by': sortBy,
      'page': page.toString(),
    };

    final uri = Uri.parse(Endpoints.products)
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'products': (data['data']['products'] as List)
            .map((e) => Product.fromJson(e))
            .toList(),
        'pagination': data['data']['pagination'],
      };
    } else {
      throw Exception('Erreur lors du chargement des produits');
    }
  }

  // 2. Détails d'un produit
  static Future<Product> getProductById(int id) async {
    final response = await http.get(
      Uri.parse(Endpoints.productDetails(id)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['data']['product']);
    } else {
      throw Exception('Produit introuvable');
    }
  }

  // 3. Produits en vedette (featured)
  static Future<List<Product>> getFeaturedProducts({int? shopId}) async {
    final queryParams = <String, String>{
      if (shopId != null) 'shop_id': shopId.toString(),
    };

    final uri = Uri.parse(Endpoints.productsFeatured)
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data']['products'] as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } else {
      throw Exception('Erreur lors du chargement des produits en vedette');
    }
  }

  // 4. Recherche de produits
  static Future<Map<String, dynamic>> searchProducts(
    String query, {
    int? shopId,
    int page = 1,
  }) async {
    return getProducts(
      search: query,
      shopId: shopId,
      page: page,
    );
  }
}
