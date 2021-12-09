import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 350,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 250,
    //   imageUrl:
    //       'https://cdn.shopify.com/s/files/1/0245/1138/1585/products/basics-comfort-fit-light-grey-satin-weave-poly-cotton-trousers-17bctr38185-422392.jpg?v=1601969399',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 120,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 280,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  // var _showFavoritesOnly = false;
  String? authToken = '';
  String? userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    // if (_showFavoritesOnly == true) {
    //   return items.where((prodItem) => prodItem.isFavorite).toList();
    // }
    return [..._items]; //returns a copy of the items instead of original list
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    var _params;
    if (filterByUser == true) {
      _params = <String, String?>{
        'auth': authToken,
        'orderBy': json.encode("creatorId"),
        'equalTo': json.encode(userId),
      };
    }
    if (filterByUser == false) {
      _params = <String, String?>{
        'auth': authToken,
      };
    }
    var url = Uri.https(
      'flutter-project-5437e-default-rtdb.asia-southeast1.firebasedatabase.app',
      '/products.json', _params);

    // final filterString = filterByUser
    //     ? {'orderBy': json.encode('creatorId'), 'equalTo': json.encode(userId)}
    //     : '';
    // var url = Uri.https(
    //   'flutter-project-5437e-default-rtdb.asia-southeast1.firebasedatabase.app',
    //   '/products.json',
    //   {
    //     'auth': authToken,
    //      filterString
    //   },
      
    // );
    
    try {
      final response = await http.get(url);
      // print(response);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == {}) {
        return;
      }
      url = Uri.https(
          'flutter-project-5437e-default-rtdb.asia-southeast1.firebasedatabase.app',
          '/userFavorites/$userId.json',
          {'auth': '$authToken'});
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          description: prodData['description'],
          imageUrl: prodData['imageUrl'],
          price: prodData['price'],
          title: prodData['title'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.https(
        'flutter-project-5437e-default-rtdb.asia-southeast1.firebasedatabase.app',
        '/products.json',
        {'auth': '$authToken'});
    try {
      final response =
          await http //tells Dart to wait before this code executes completely.
              .post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId,
          // 'isFavorite': product.isFavorite,
        }),
      );
      final newProduct = Product(
        id: json.decode(response.body)['name'],
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        title: product.title,
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.https(
          'flutter-project-5437e-default-rtdb.asia-southeast1.firebasedatabase.app',
          '/products.json',
          {'auth': '$authToken'});
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {}
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.https(
        'flutter-project-5437e-default-rtdb.asia-southeast1.firebasedatabase.app',
        '/products.json',
        {'auth': '$authToken'});
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    dynamic existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
