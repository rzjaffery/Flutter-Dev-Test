import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/product_model.dart';

// All Firebase CRUD operations related to products will be handled in this service class

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections reference
  CollectionReference get _productsRef => _db.collection('products');

  //CREATE
  /// Adds a new product document and returns the created [ProductModel].
  Future<ProductModel> createProduct({
    required String userId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    try {
      final now = DateTime.now();

      // Build the product (id left empty; Firestore will assign one)
      final product = ProductModel(
        id: '',
        userId: userId,
        name: name,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
        createdAt: now,
        updatedAt: now,
      );

      // Let Firestore auto-generate the document ID
      final DocumentReference docRef = await _productsRef.add(product.toMap());

      // Return the product with the real Firestore ID
      return ProductModel.fromMap(product.toMap(), docRef.id);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // READ PAGINATED
  /// Fetches one page of products belonging to [userId].
  /// Pass [lastDocument] to continue from the previous page (cursor pagination).
  Future<List<ProductModel>> getProducts({
    required String userId,
    int pageSize = 6,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _productsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      // If we have a cursor, start after the last seen document
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Fetches the raw [QuerySnapshot] for a page — needed to obtain the cursor.
  Future<QuerySnapshot> getProductsSnapshot({
    required String userId,
    int pageSize = 6,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _productsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.get();
  }

  // READ SINGLE
  /// Fetches a single product by its [productId].
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final DocumentSnapshot doc = await _productsRef.doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // UPDATE
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
  }) async {
    try {
      await _productsRef.doc(productId).update({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // DELETE
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}