import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product_model.dart';
import 'user_model.dart';
import 'dart:io';
import '../admin_story_user_model.dart';
import '../group_model.dart';
import 'screens/post_page.dart';
import 'app_user_model.dart';
import '../active_ingredient_model.dart';
import '../medication_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.17:5000";
  static Future<String?> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("$baseUrl/api/auth/upload-profile-image/$userId"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      final decoded = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        return decoded["profileImage"];
      } else {
        print("Upload failed: $responseBody");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/auth/update-profile/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "password": password,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<bool> removeProfileImage({
    required String userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/auth/remove-profile-image/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      print("REMOVE STATUS: ${response.statusCode}");
      print("REMOVE BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("REMOVE IMAGE ERROR: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> saveOnboarding({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/auth/onboarding/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> getUserProfile({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/auth/user/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<ProductModel>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load products: ${response.statusCode} ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> toggleFavorite({
    required String userId,
    required String productId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/favorites/toggle"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<ProductModel>> fetchFavorites(String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/favorites/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load favorites");
    }
  }

  static Future<dynamic> addToCart({
    required String userId,
    required String productId,
    required int quantity,
    required String storeId,
    required dynamic price,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/cart/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
        "storeId": storeId,
        "quantity": quantity,
        "price": price,
        "currency": currency,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> fetchCart(String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/cart/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<dynamic> removeFromCart({
    required String userId,
    required String productId,
    required String storeId,
  }) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/cart/remove"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
        "storeId": storeId,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<dynamic> updateCartQuantity({
    required String userId,
    required String productId,
    required String storeId,
    required int quantity,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/cart/update"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
        "storeId": storeId,
        "quantity": quantity,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required String city,
    required String streetAddress,
    required String note,
    required String paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double total,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/orders/create"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "city": city,
        "streetAddress": streetAddress,
        "note": note,
        "paymentMethod": paymentMethod,
        "subtotal": subtotal,
        "deliveryFee": deliveryFee,
        "total": total,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<ProductModel> fetchProductById(String productId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/products/$productId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductModel.fromJson(data);
    } else {
      throw Exception(
        'Failed to load product: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> addProduct({
    required Map<String, dynamic> productData,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/products"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(productData),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String title,
    required String comment,
    bool? repurchase,
    bool? improvedSkin,
    bool? wasGift,
    bool? adverseReaction,
    String texture = "",
    String usageWeeks = "",
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/products/$productId/reviews"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "rating": rating,
        "title": title,
        "comment": comment,
        "repurchase": repurchase,
        "improvedSkin": improvedSkin,
        "wasGift": wasGift,
        "adverseReaction": adverseReaction,
        "texture": texture,
        "usageWeeks": usageWeeks,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<UserModel?> fetchUserProfile(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/api/auth/user/$userId");
      print("REQUEST URL: $url");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print("FETCH PROFILE ERROR: $e");
      return null;
    }
  }

  static Future<List<UserCollectionModel>?> addCollection({
    required String userId,
    required String title,
    List<String> images = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/user/$userId/collections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'images': images,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return (data['collections'] as List<dynamic>)
            .map((e) => UserCollectionModel.fromJson(e))
            .toList();
      } else {
        print('Add collection failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Add collection error: $e');
      return null;
    }
  }

  static Future<bool> updateCollectionName({
    required String collectionId,
    required String newTitle,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/collection/$collectionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': newTitle,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteCollection({
    required String collectionId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/collection/$collectionId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('deleteCollection STATUS = ${response.statusCode}');
      print('deleteCollection BODY = ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('deleteCollection ERROR = $e');
      return false;
    }
  }

  static Future<List<AdminStoryUserModel>> getAllUsersForAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/users'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => AdminStoryUserModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<int> getProductsCount() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/count'));

    print("PRODUCTS COUNT STATUS: ${response.statusCode}");
    print("PRODUCTS COUNT BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Failed to load products count');
    }
  }

  static Future<GroupModel> fetchGroupBySlug(String slug) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups/$slug"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GroupModel.fromJson(data);
    } else {
      throw Exception("Failed to fetch group");
    }
  }

  static Future<List<ProductModel>> fetchGroupProducts(String slug) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups/$slug/products"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch group products");
    }
  }

  static Future<List<GroupModel>> fetchGroups() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GroupModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch groups");
    }
  }

  static Future<bool> joinGroup({
    required String slug,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/groups/$slug/join"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Failed to join group");
    }
  }

  static Future<bool> fetchJoinStatus({
    required String slug,
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups/$slug/join-status/$userId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["isJoined"] ?? false;
    } else {
      throw Exception("Failed to fetch join status");
    }
  }

  static Future<bool> leaveGroup({
    required String slug,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/groups/$slug/leave"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Failed to leave group");
    }
  }

  static Future<Map<String, dynamic>> addReviewPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    required String productId,
    required String productName,
    required String productImage,
    required double rating,
    required bool? repurchase,
    required bool? improvedSkin,
    required bool? wasGift,
    required bool? adverseReaction,
    required String texture,
    required String usageWeeks,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/group-posts/review"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "userAvatar": userAvatar,
        "content": content,
        "productId": productId,
        "productName": productName,
        "productImage": productImage,
        "rating": rating,
        "repurchase": repurchase,
        "improvedSkin": improvedSkin,
        "wasGift": wasGift,
        "adverseReaction": adverseReaction,
        "texture": texture,
        "usageWeeks": usageWeeks,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<GroupPostModel>> fetchPosts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/group-posts"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => GroupPostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      throw Exception("Failed to load posts");
    }
  }

  static Future<bool> deletePost(String postId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/group-posts/$postId"),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/group-posts/$postId/like"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String comment,
    String? parentCommentId,
    String replyToUserName = "",
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/group-posts/$postId/comments"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "userAvatar": userAvatar,
        "comment": comment,
        "parentCommentId": parentCommentId,
        "replyToUserName": replyToUserName,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> toggleSavePost({
    required String userId,
    required String postId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/user/$userId/save-post/$postId"),
      headers: {"Content-Type": "application/json"},
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<GroupPostModel>> fetchSavedPosts(String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/auth/user/$userId/saved-posts"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => GroupPostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      throw Exception("Failed to load saved posts");
    }
  }

  static Future<Map<String, dynamic>> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/group-posts/$postId/comments/$commentId/like"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/group-posts/$postId/comments/$commentId"),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  static Future<bool> editComment({
    required String postId,
    required String commentId,
    required String comment,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/group-posts/$postId/comments/$commentId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "comment": comment,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<GroupModel>> fetchGroupsByType(String groupType) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups/type/$groupType"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GroupModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch groups by type");
    }
  }

  static Future<Map<String, dynamic>> addQuestionPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    required String productId,
    required String productName,
    required String productImage,
    required String groupId,
    required String groupTitle,
    required String groupSlug,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/group-posts/question"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "userAvatar": userAvatar,
        "content": content,
        "productId": productId,
        "productName": productName,
        "productImage": productImage,
        "groupId": groupId,
        "groupTitle": groupTitle,
        "groupSlug": groupSlug,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<bool> editPost({
    required String postId,
    required String content,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/group-posts/$postId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "content": content,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> addUpdatePost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    required String productId,
    required String productName,
    required String productImage,
    required String groupId,
    required String groupTitle,
    required String groupSlug,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/group-posts/update"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "userAvatar": userAvatar,
        "content": content,
        "productId": productId,
        "productName": productName,
        "productImage": productImage,
        "groupId": groupId,
        "groupTitle": groupTitle,
        "groupSlug": groupSlug,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<String?> uploadPostImage(File imageFile) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/api/group-posts/upload"),
    );

    request.files.add(
      await http.MultipartFile.fromPath("image", imageFile.path),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData);
      return data["imageUrl"];
    } else {
      return null;
    }
  }
//   static Future<List<GroupModel>> fetchGroupsByType(String groupType) async {
//   final response = await http.get(
//     Uri.parse("$baseUrl/api/groups/type/$groupType"),
//   );

//   if (response.statusCode == 200) {
//     final List data = jsonDecode(response.body);
//     return data.map((e) => GroupModel.fromJson(e)).toList();
//   } else {
//     throw Exception("Failed to load groups");
//   }
// }
  static Future<List<AppUserModel>> fetchGroupPeople(String groupSlug) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups/$groupSlug/people"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AppUserModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load group people");
    }
  }

  static Future<List<GroupPostModel>> fetchPostsByGroup(
      String groupSlug) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/group-posts/group/$groupSlug"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => GroupPostModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load group discussions");
    }
  }

  static Future<List<GroupPostModel>> fetchProductCategoryDiscussionPosts(
      String groupSlug) async {
    final response = await http.get(
      Uri.parse(
          "$baseUrl/api/group-posts/product-category-discussion/$groupSlug"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => GroupPostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      throw Exception("Failed to load product category discussion posts");
    }
  }

  static Future<List<ProductModel>> fetchProductsByBrand(String brand) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/products/brand/$brand"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products by brand");
    }
  }

  static Future<List<GroupPostModel>> fetchReviewPostsByProduct(
      String productId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/group-posts/product-review-posts/$productId"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => GroupPostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      throw Exception("Failed to load product review posts");
    }
  }

  // static Future<bool> addProductToCollection({
  //   required String collectionId,
  //   required String imageUrl,
  // }) async {
  //   final response = await http.put(
  //     Uri.parse('$baseUrl/api/auth/collection/$collectionId/add-product'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'imageUrl': imageUrl,
  //     }),
  //   );

  //   return response.statusCode == 200;
  // }
  static Future<bool> addProductToCollection({
    required String collectionId,
    required String imageUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/collection/$collectionId/add-product'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'imageUrl': imageUrl,
      }),
    );

    print("ADD TO COLLECTION STATUS: ${response.statusCode}");
    print("ADD TO COLLECTION BODY: ${response.body}");

    return response.statusCode == 200;
  }

  static Future<bool> isProductInAnyCollection({
    required String userId,
    required String imageUrl,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/auth/user/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    print("SAVED STATE STATUS: ${response.statusCode}");
    print("SAVED STATE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List collections = data["collections"] ?? [];

      for (final collection in collections) {
        final List images = collection["images"] ?? [];

        if (images.contains(imageUrl)) {
          return true;
        }
      }
    }

    return false;
  }

  static Future<List<ActiveIngredientModel>> fetchActiveIngredients() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/ingredients"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((e) => ActiveIngredientModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } else {
      throw Exception("Failed to load active ingredients");
    }
  }

  static Future<Map<String, dynamic>> fetchActiveIngredientDetails(
    String slug,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/ingredients/$slug"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load ingredient details");
    }
  }

  static Future<List<ProductModel>> fetchProductsByConcern(
      String concern) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/products/concern/$concern"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products by concern");
    }
  }

  static Future<List<GroupPostModel>> fetchMedicationDiscussionPosts(
    String groupSlug,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/group-posts/medication-discussion/$groupSlug"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => GroupPostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      throw Exception("Failed to load medication discussion posts");
    }
  }

  static Future<List<MedicationModel>> fetchMedicationsByCondition(
    String condition,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/medications/condition/$condition"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MedicationModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load medications");
    }
  }

  static Future<Map<String, dynamic>> scanProductImage({
    required File imageFile,
    required String userId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/product-scan');

    final request = http.MultipartRequest('POST', uri);

    request.fields['userId'] = userId;

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<dynamic>> fetchScanHistory(String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/product-scan/history/$userId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load scan history");
    }
  }

  static Future<bool> deleteScanHistory(String scanId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/product-scan/history/$scanId"),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> analyzeProductWithAI({
    required String productId,
    String userSkinType = "",
    List<String> userConcerns = const [],
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/product-analyze"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "productId": productId,
        "userSkinType": userSkinType,
        "userConcerns": userConcerns,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<bool> followUser({
    required String targetUserId,
    required String currentUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/$targetUserId/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentUserId': currentUserId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("FOLLOW USER ERROR: $e");
      return false;
    }
  }

  static Future<bool> unfollowUser({
    required String targetUserId,
    required String currentUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/$targetUserId/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentUserId': currentUserId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("UNFOLLOW USER ERROR: $e");
      return false;
    }
  }

  static Future<List<dynamic>> fetchStoresForProduct(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/store-products/product/$productId'),
    );

    print("STORES STATUS = ${response.statusCode}");
    print("STORES BODY = ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stores for product');
    }
  }

  static Future<List<dynamic>> fetchProductsByStore(String storeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/store-products/store/$storeId'),
    );

    print("STORE PRODUCTS STATUS = ${response.statusCode}");
    print("STORE PRODUCTS BODY = ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load store products');
    }
  }

  static Future<List<dynamic>> fetchStores() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stores'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stores');
    }
  }

  static Future<List<dynamic>> fetchAllStoreProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/store-products'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load store products');
    }
  }

  static Future<List<dynamic>> fetchApprovedAds() async {
    final response = await http.get(Uri.parse("$baseUrl/api/ads/approved"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load ads");
    }
  }

  static Future<List<dynamic>> fetchTrendingStoreProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/store-products/trending'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trending products');
    }
  }

  static Future<Map<String, dynamic>> fetchMySellerStore() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getString("userId");

    final response = await http.get(
      Uri.parse("$baseUrl/api/stores/seller/$sellerId"),
    );

    print("SELLER STORE STATUS = ${response.statusCode}");
    print("SELLER STORE BODY = ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load seller store");
    }
  }

  static Future<Map<String, dynamic>> addStoreProduct({
    required String productId,
    required double price,
    required int stockCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final sellerId = prefs.getString("userId");
    final store = await fetchMySellerStore();

    final response = await http.post(
      Uri.parse("$baseUrl/api/store-products"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "storeId": store["_id"],
        "productId": productId,
        "sellerId": sellerId,
        "price": price,
        "currency": "ILS",
        "stockCount": stockCount,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> createAdOffer({
    required String title,
    required String subtitle,
    required String imageUrl,
    required String buttonText,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getString("userId");
    final store = await fetchMySellerStore();

    final response = await http.post(
      Uri.parse("$baseUrl/api/ads"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "storeId": store["_id"],
        "sellerId": sellerId,
        "title": title,
        "subtitle": subtitle,
        "imageUrl": imageUrl,
        "buttonText": buttonText,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<dynamic>> fetchSellerAds() async {
    final prefs = await SharedPreferences.getInstance();
    final sellerId = prefs.getString("userId");

    final response = await http.get(
      Uri.parse("$baseUrl/api/ads/seller/$sellerId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load seller ads");
    }
  }

  static Future<Map<String, dynamic>> rateStoreForOrder({
    required String orderId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/orders/$orderId/rate-store"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "rating": rating,
        "comment": comment,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }
}
