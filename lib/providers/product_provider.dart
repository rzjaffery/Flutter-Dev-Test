import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:product_catalogue/services/product_service.dart';
import '../models/product_model.dart';

// Manages the product list, pagination cursor, and CRUD state for the UI.

enum ProductStatus { idle, loading, loadingMore, success, error }

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  // State variables
  List<ProductModel> _products = [];
  ProductStatus _status = ProductStatus.idle;
  String? _errorMessage;

  // Pagination cursor
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  static const int _pageSize = 6;

  // Getters for external access
  List<ProductModel> get products => List.unmodifiable(_products);
  ProductStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoading => _status == ProductStatus.loading;
  bool get isLoadingMore => _status == ProductStatus.loadingMore;

  // Fetch the first page of products for the given userId
  Future<void> loadProducts(String userId) async {
    _status = ProductStatus.loading;
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _productService.getProductsSnapshot(
        userId: userId,
        pageSize: _pageSize,
      );

      _products = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Store cursor for next page
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      // If we got fewer docs than requested, we've reached the end
      _hasMore = snapshot.docs.length == _pageSize;
      _status = ProductStatus.success;
    } catch (e) {
      _status = ProductStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // Fetch the next page of products for the given userId
  Future<void> loadMoreProducts(String userId) async {
    if (!_hasMore || _status == ProductStatus.loadingMore) return;

    _status = ProductStatus.loadingMore;
    notifyListeners();

    try {
      final snapshot = await _productService.getProductsSnapshot(
        userId: userId,
        pageSize: _pageSize,
        lastDocument: _lastDocument,
      );

      final newProducts = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      _products.addAll(newProducts);

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length == _pageSize;
      _status = ProductStatus.success;
    } catch (e) {
      _status = ProductStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // CREATE
  Future<bool> createProduct({
    required String userId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final product = await _productService.createProduct(
        userId: userId,
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
      );

      // Prepend to list so the new item appears at the top
      _products.insert(0, product);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // UPDATE
  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    try {
      await _productService.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
      );

      // Reflect update locally without re-fetching from Firestore
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          name: name,
          description: description,
          price: price,
          category: category,
          imageUrl: imageUrl,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // DELETE
  Future<bool> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // CLEAR
  void clear() {
    _products = [];
    _status = ProductStatus.idle;
    _errorMessage = null;
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();
  }
}
