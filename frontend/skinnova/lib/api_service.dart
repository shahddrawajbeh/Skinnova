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
  static const String baseUrl = "http://10.0.2.2:5000";
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

  // ── Forgot password / reset password ──────────────────────────────────────

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body)
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"message": "Network error"}
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
        }),
      );
      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body)
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"message": "Network error"}
      };
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );
      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body)
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "data": {"message": "Network error"}
      };
    }
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
    String paymentStatus = "pending",
    String? cardLast4,
  }) async {
    final body = <String, dynamic>{
      "userId": userId,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "city": city,
      "streetAddress": streetAddress,
      "note": note,
      "paymentMethod": paymentMethod,
      "paymentStatus": paymentStatus,
      "subtotal": subtotal,
      "deliveryFee": deliveryFee,
      "total": total,
    };
    if (cardLast4 != null) body["cardLast4"] = cardLast4;

    final response = await http.post(
      Uri.parse("$baseUrl/api/orders/create"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
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
    String userId = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/collection/$collectionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': newTitle, 'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteCollection({
    required String collectionId,
    String userId = '',
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/collection/$collectionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeProductFromCollection({
    required String collectionId,
    required String imageUrl,
    String userId = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/collection/$collectionId/remove-product'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageUrl': imageUrl, 'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
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
    String userId = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/collection/$collectionId/add-product'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageUrl': imageUrl, 'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
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
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/orders/$orderId/rate-store"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": userName,
        "rating": rating,
        "comment": comment,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<List<dynamic>> fetchPendingStoreReviews() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/stores/reviews/pending"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception("Failed to load pending store reviews");
  }

  static Future<bool> approveStoreReview({
    required String storeId,
    required String reviewId,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/stores/reviews/$storeId/$reviewId/approve"),
    );
    return response.statusCode == 200;
  }

  static Future<bool> rejectStoreReview({
    required String storeId,
    required String reviewId,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/stores/reviews/$storeId/$reviewId/reject"),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> reportStore({
    required String storeId,
    required String userId,
    required String reason,
    String details = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/store-reports"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "storeId": storeId,
          "userId": userId,
          "reason": reason,
          "details": details,
        }),
      );
      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {"statusCode": 500, "data": {}};
    }
  }

  static Future<bool> hideStore({
    required String userId,
    required String storeId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/auth/user/$userId/hide-store/$storeId"),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Returns list of populated store objects (with _id, storeName, logoUrl, city, rating)
  static Future<List<dynamic>> fetchHiddenStores(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/auth/user/$userId/hidden-stores"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> unhideStore({
    required String userId,
    required String storeId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/auth/user/$userId/unhide-store/$storeId"),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Store Follow ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> followStore({
    required String userId,
    required String storeId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId/follow/$userId"),
      );
      final data = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": data};
    } catch (e) {
      return {"statusCode": 500, "data": {}};
    }
  }

  static Future<Map<String, dynamic>> unfollowStore({
    required String userId,
    required String storeId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId/unfollow/$userId"),
      );
      final data = jsonDecode(response.body);
      return {"statusCode": response.statusCode, "data": data};
    } catch (e) {
      return {"statusCode": 500, "data": {}};
    }
  }

  // Returns populated store objects with storeName, logoUrl, city, followersCount, rating
  static Future<List<dynamic>> fetchFollowedStores(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/auth/user/$userId/followed-stores"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/notifications/$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/notifications/$userId/unread-count"),
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body)["count"] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // static Future<void> markAllNotificationsRead(String userId) async {
  //   try {
  //     await http.put(
  //       Uri.parse("$baseUrl/api/notifications/$userId/mark-all-read"),
  //     );
  //   } catch (_) {}
  // }

  // ── Admin: Store Reports ───────────────────────────────────────────────────

  static Future<List<dynamic>> fetchStoreReports({String? status}) async {
    try {
      final uri = status != null
          ? Uri.parse("$baseUrl/api/store-reports?status=$status")
          : Uri.parse("$baseUrl/api/store-reports");
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> markStoreReportReviewed({
    required String reportId,
    String adminNote = "",
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/store-reports/$reportId/reviewed"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"adminNote": adminNote}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> markStoreReportDismissed({
    required String reportId,
    String adminNote = "",
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/store-reports/$reportId/dismissed"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"adminNote": adminNote}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchUnverifiedStores() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/stores/admin/unverified"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> fetchVerifiedStores() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/stores/admin/verified"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> verifyStore({
    required String storeId,
    String adminId = "",
    String verificationLevel = "standard",
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "adminId": adminId,
          "verificationLevel": verificationLevel,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unverifyStore({required String storeId}) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId/unverify"),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Seller Center ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchStoreAnalytics(
      String storeId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/stores/$storeId/analytics"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<List<dynamic>> fetchOrders(String userId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/orders/$userId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["orders"] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchOrderById(String orderId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/orders/detail/$orderId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["order"];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> fetchSellerOrdersByStore(String storeId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/orders/store/$storeId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["orders"] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/orders/$orderId/status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchAllSellerProducts(String storeId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/api/store-products/store/$storeId"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateStoreProductData({
    required String spId,
    double? price,
    int? stockCount,
    bool? isAvailable,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (price != null) body["price"] = price;
      if (stockCount != null) body["stockCount"] = stockCount;
      if (isAvailable != null) body["isAvailable"] = isAvailable;
      final response = await http.put(
        Uri.parse("$baseUrl/api/store-products/$spId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteStoreProduct(String spId) async {
    try {
      final response =
          await http.delete(Uri.parse("$baseUrl/api/store-products/$spId"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStoreStatus({
    required String storeId,
    required bool isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isActive": isActive}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addRecentlyUsedProduct({
    required String userId,
    required String productId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/recently-used'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId}),
    );
    return res.statusCode == 200;
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/change-password/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {}};
    }
  }

  static Future<bool> deleteAccount(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/auth/delete-account/$userId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchScanPrivacy(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/scan-privacy/$userId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<bool> updateScanPrivacy({
    required String userId,
    required bool allowScanHistory,
    required bool allowImageStorage,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/scan-privacy/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'allowScanHistory': allowScanHistory,
          'allowImageStorage': allowImageStorage,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> submitSupportMessage({
    required String type,
    required String subject,
    required String message,
    String userId = '',
    String userName = '',
    String email = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/support/contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'email': email,
          'type': type,
          'subject': subject,
          'message': message,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeRecentlyUsedProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/auth/recently-used/remove'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'productId': productId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchSkinScanHistory(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/skin-scan/history/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      if (data['history'] is List) {
        return data['history'];
      }

      if (data['scans'] is List) {
        return data['scans'];
      }

      return [];
    } else {
      throw Exception('Failed to load skin scan history');
    }
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> startConversation({
    required String userId,
    required String storeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/start"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "storeId": storeId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {"error": "Failed"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getChatMessages(
    String conversationId, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/api/chat/messages/$conversationId?page=$page&limit=40"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {"messages": [], "total": 0, "hasMore": false};
    } catch (e) {
      return {"messages": [], "total": 0, "hasMore": false};
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required String conversationId,
    required String senderId,
    required String senderType,
    String messageType = "text",
    String text = "",
    Map<String, dynamic>? productSnapshot,
  }) async {
    try {
      final body = <String, dynamic>{
        "conversationId": conversationId,
        "senderId": senderId,
        "senderType": senderType,
        "messageType": messageType,
        "text": text,
        if (productSnapshot != null) "productSnapshot": productSnapshot,
      };
      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {"error": "Failed"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  static Future<void> markChatSeen({
    required String conversationId,
    required String viewerType,
  }) async {
    try {
      await http.put(
        Uri.parse("$baseUrl/api/chat/seen/$conversationId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"viewerType": viewerType}),
      );
    } catch (_) {}
  }

  static Future<List<dynamic>> fetchSellerConversations(String sellerId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/chat/seller/conversations/$sellerId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchStoreById(String storeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stores/$storeId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load store');
    }
  }

  static Future<bool> updateStoreProfile({
    required String storeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStoreSettings({
    required String storeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/stores/$storeId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchStoreReviews(String storeId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/stores/$storeId/reviews"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> fetchSellerNotifications(String userId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/api/notifications/$userId"));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> markNotificationRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/notifications/$notificationId/read"),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> markAllNotificationsRead(String userId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/notifications/$userId/mark-all-read"),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// GET /api/notifications/settings/:userId
  static Future<Map<String, bool>?> getNotificationSettings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/notifications/settings/$userId"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'inApp': data['inApp'] as bool? ?? true,
          'push': data['push'] as bool? ?? true,
          'email': data['email'] as bool? ?? true,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// PUT /api/notifications/settings/:userId
  static Future<bool> updateNotificationSettings(
    String userId, {
    required bool inApp,
    required bool push,
    required bool email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/notifications/settings/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'inApp': inApp, 'push': push, 'email': email}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendSellerSupportMessage(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/support/seller"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ── Admin: Support Center ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchUserSupportMessages({
    String? type,
    String? status,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page', 'limit': '100'};
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (status != null && status.isNotEmpty) params['status'] = status;
      final uri = Uri.parse('$baseUrl/api/support/user-messages')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'messages': [], 'total': 0};
    } catch (e) {
      return {'messages': [], 'total': 0};
    }
  }

  static Future<bool> updateUserSupportMessageStatus(
    String messageId,
    String status, {
    String adminNote = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/support/user-messages/$messageId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status, 'adminNote': adminNote}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteUserSupportMessage(String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/support/user-messages/$messageId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> uploadStoreLogo({
    required String storeId,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/stores/$storeId/upload-logo'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      if (response.statusCode == 200) return data['logoUrl'];
      print('UPLOAD LOGO FAILED: $body');
      return null;
    } catch (e) {
      print('UPLOAD LOGO ERROR: $e');
      return null;
    }
  }

  static Future<String?> uploadStoreCover({
    required String storeId,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/stores/$storeId/upload-cover'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      if (response.statusCode == 200) return data['coverImageUrl'];
      print('UPLOAD COVER FAILED: $body');
      return null;
    } catch (e) {
      print('UPLOAD COVER ERROR: $e');
      return null;
    }
  }

  static Future<String?> addStoreGalleryImage({
    required String storeId,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/stores/$storeId/gallery'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      if (response.statusCode == 200) return data['imageUrl'];
      print('GALLERY ADD FAILED: $body');
      return null;
    } catch (e) {
      print('GALLERY ADD ERROR: $e');
      return null;
    }
  }

  static Future<bool> deleteStoreGalleryImage({
    required String storeId,
    required String imageUrl,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/stores/$storeId/gallery'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': imageUrl}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('GALLERY DELETE ERROR: $e');
      return false;
    }
  }

  // static Future<List<dynamic>> fetchRecentlyUsedUsers(String productId) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/api/auth/product/$productId/recently-used-users'),
  //     );
  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body) as List<dynamic>;
  //     }
  //     return [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  static Future<Map<String, dynamic>> fetchProductAnalytics(
      String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId/analytics'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<String?> uploadAdImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/ads/upload-image'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      if (response.statusCode == 200) return data['imageUrl'];
      print('UPLOAD AD IMAGE FAILED: $body');
      return null;
    } catch (e) {
      print('UPLOAD AD IMAGE ERROR: $e');
      return null;
    }
  }

  static Future<List<dynamic>> fetchRecentlyUsedUsers(
    String productId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/auth/product/$productId/recently-used-users',
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Skinova Beauty AI — sends a chat message to the shop AI backend.
  // Returns {statusCode, data} where data contains success, mode, result.
  static Future<Map<String, dynamic>> sendShopAiChat({
    required String userId,
    required String mode,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/shop-ai/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "mode": mode,
          "message": message,
        }),
      );
      return {
        "statusCode": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "statusCode": 503,
        "data": {
          "success": false,
          "message": "Network error. Check your connection."
        },
      };
    }
  }

  // Try Before You Buy — upload a photo + productId and receive AI-generated preview.
  static Future<Map<String, dynamic>> tryBeforeBuyUpload({
    required String userId,
    required String productId,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/try-before-buy'),
      );
      request.fields['userId'] = userId;
      request.fields['productId'] = productId;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return {
        'statusCode': streamed.statusCode,
        'data': jsonDecode(body),
      };
    } catch (e) {
      return {
        'statusCode': 503,
        'data': {
          'success': false,
          'message': 'Network error. Please try again.'
        },
      };
    }
  }

  // Try Before You Buy — use an existing scan photo (by URL) instead of uploading.
  static Future<Map<String, dynamic>> tryBeforeBuyWithUrl({
    required String userId,
    required String productId,
    required String imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/try-before-buy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'imageUrl': imageUrl,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 503,
        'data': {
          'success': false,
          'message': 'Network error. Please try again.'
        },
      };
    }
  }

  // Fetch the latest skin scan for a user (returns null if none).
  static Future<Map<String, dynamic>?> fetchLatestSkinScan(
      String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/skin-scan/history/$userId'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) return data.first as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Fetch all Try Before You Buy history records for a user.
  static Future<List<dynamic>> fetchTryBeforeBuyHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/try-before-buy/history/$userId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Delete a Try Before You Buy preview by its record ID.
  static Future<bool> deleteTryBeforeBuyRecord(String recordId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/try-before-buy/$recordId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── AI Product Suitability & Routine Safety ──────────────────────────────

  static Future<Map<String, dynamic>> analyzeProductSuitability({
    required String userId,
    required String productId,
    bool includeRoutine = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/product-suitability'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'productId': productId,
        'includeRoutine': includeRoutine,
      }),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> checkRoutineSafety(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/routine-safety'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body),
    };
  }

  // ── Product Usage Reminders ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> createProductUsageReminder(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/product-usage-reminders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body)
    };
  }

  static Future<List<dynamic>> getProductUsageReminders(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/product-usage-reminders/user/$userId'),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body)['reminders'] as List?) ?? [];
    }
    throw Exception('Failed to load reminders');
  }

  static Future<Map<String, dynamic>> updateProductUsageReminder(
      String reminderId, String userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/product-usage-reminders/$reminderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, ...data}),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body)
    };
  }

  static Future<bool> toggleProductUsageReminder(
      String reminderId, String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/product-usage-reminders/$reminderId/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteProductUsageReminder(
      String reminderId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$baseUrl/api/product-usage-reminders/$reminderId?userId=$userId'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Purchase History
  static Future<bool> confirmOrderReceived(
      String orderId, String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/confirm-received/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchPurchaseHistory(
      String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/purchase-history/$userId'),
    );
    return {
      'statusCode': response.statusCode,
      'data': jsonDecode(response.body),
    };
  }

  // ─── Admin API Methods ──────────────────────────────────────────────────────

  static Map<String, String> _adminHeaders(String adminId) => {
        'Content-Type': 'application/json',
        'x-admin-id': adminId,
      };

  // Stats
  static Future<Map<String, dynamic>> adminGetStats(String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/stats'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load stats');
  }

  // Analytics Charts
  static Future<Map<String, dynamic>> adminGetAnalyticsCharts(
      String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/analytics/charts'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load analytics charts');
  }

  // Users
  static Future<Map<String, dynamic>> adminGetUsers(String adminId,
      {String search = '', String role = '', int page = 1}) async {
    final uri = Uri.parse('$baseUrl/api/admin/users').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (role.isNotEmpty) 'role': role,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load users');
  }

  static Future<Map<String, dynamic>> adminGetUser(
      String adminId, String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load user');
  }

  static Future<Map<String, dynamic>> adminCreateUser(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to create user');
  }

  static Future<Map<String, dynamic>> adminUpdateUser(
      String adminId, String userId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update user');
  }

  static Future<bool> adminToggleUserActive(
      String adminId, String userId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/users/$userId/toggle-active'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminChangeUserRole(
      String adminId, String userId, String role) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/users/$userId/role'),
      headers: _adminHeaders(adminId),
      body: jsonEncode({'role': role}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteUser(String adminId, String userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  // Sellers
  static Future<Map<String, dynamic>> adminGetSellers(String adminId,
      {String search = '', int page = 1}) async {
    final uri =
        Uri.parse('$baseUrl/api/admin/sellers').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load sellers');
  }

  static Future<List<dynamic>> adminGetSellerStores(
      String adminId, String sellerId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/sellers/$sellerId/stores'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load seller stores');
  }

  static Future<bool> adminApproveSeller(String adminId, String userId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/sellers/$userId/approve'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminRejectSeller(String adminId, String userId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/sellers/$userId/reject'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminToggleSellerActive(
      String adminId, String sellerId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/sellers/$sellerId/toggle-active'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteSeller(String adminId, String sellerId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/sellers/$sellerId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  // Stores
  static Future<Map<String, dynamic>> adminGetStores(String adminId,
      {String search = '', int page = 1}) async {
    final uri =
        Uri.parse('$baseUrl/api/admin/stores').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load stores');
  }

  static Future<Map<String, dynamic>> adminGetStore(
      String adminId, String storeId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/stores/$storeId'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load store');
  }

  static Future<Map<String, dynamic>> adminCreateStore(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/stores'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Failed to create store');
  }

  static Future<Map<String, dynamic>> adminUpdateStore(
      String adminId, String storeId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/stores/$storeId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update store');
  }

  static Future<bool> adminToggleStoreActive(
      String adminId, String storeId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/stores/$storeId/toggle-active'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminToggleStoreVerified(
      String adminId, String storeId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/stores/$storeId/toggle-verified'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteStore(String adminId, String storeId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/stores/$storeId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<String?> adminUploadStoreImage(
      String adminId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/stores/upload-image'),
    );
    request.headers['x-admin-id'] = adminId;
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body)['imageUrl'];
    return null;
  }

  // Products
  static Future<Map<String, dynamic>> adminGetProducts(String adminId,
      {String search = '', String category = '', int page = 1}) async {
    final uri =
        Uri.parse('$baseUrl/api/admin/products').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (category.isNotEmpty) 'category': category,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load products');
  }

  static Future<Map<String, dynamic>> adminGetProduct(
      String adminId, String productId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/products/$productId'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load product');
  }

  static Future<Map<String, dynamic>> adminCreateProduct(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/products'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Failed to create product');
  }

  static Future<Map<String, dynamic>> adminUpdateProduct(
      String adminId, String productId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/products/$productId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update product');
  }

  static Future<bool> adminToggleProductHidden(
      String adminId, String productId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/products/$productId/toggle-hidden'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteProduct(
      String adminId, String productId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/products/$productId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<String?> adminUploadProductImage(
      String adminId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/products/upload-image'),
    );
    request.headers['x-admin-id'] = adminId;
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body)['imageUrl'];
    return null;
  }

  // Ads
  static Future<Map<String, dynamic>> adminGetAds(String adminId,
      {String status = '', String placement = '', int page = 1}) async {
    final uri = Uri.parse('$baseUrl/api/admin/ads').replace(queryParameters: {
      if (status.isNotEmpty) 'status': status,
      if (placement.isNotEmpty) 'placement': placement,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load ads');
  }

  static Future<Map<String, dynamic>> adminCreateAd(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/ads'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Failed to create ad');
  }

  static Future<Map<String, dynamic>> adminUpdateAd(
      String adminId, String adId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/ads/$adId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update ad');
  }

  static Future<bool> adminApproveAd(String adminId, String adId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/ads/$adId/approve'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminRejectAd(String adminId, String adId,
      {String note = ''}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/ads/$adId/reject'),
      headers: _adminHeaders(adminId),
      body: jsonEncode({'adminNote': note}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminToggleAdActive(String adminId, String adId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/ads/$adId/toggle-active'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteAd(String adminId, String adId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/ads/$adId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<String?> adminUploadAdImage(
      String adminId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/ads/upload-image'),
    );
    request.headers['x-admin-id'] = adminId;
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body)['imageUrl'];
    return null;
  }

  // Home Settings
  static Future<Map<String, dynamic>> adminGetHomeSettings(
      String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/home-settings'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load home settings');
  }

  static Future<Map<String, dynamic>> adminUpdateHomeSettings(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/home-settings'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update home settings');
  }

  static Future<String?> adminUploadHeroImage(
      String adminId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/home-settings/upload-image'),
    );
    request.headers['x-admin-id'] = adminId;
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body)['imageUrl'];
    return null;
  }

  // Skin Groups
  static Future<List<dynamic>> adminGetSkinGroups(String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/skin-groups'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load skin groups');
  }

  static Future<Map<String, dynamic>> adminCreateSkinGroup(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/skin-groups'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Failed to create skin group');
  }

  static Future<Map<String, dynamic>> adminUpdateSkinGroup(
      String adminId, String groupId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/skin-groups/$groupId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update skin group');
  }

  static Future<bool> adminToggleSkinGroupActive(
      String adminId, String groupId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/skin-groups/$groupId/toggle-active'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteSkinGroup(
      String adminId, String groupId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/skin-groups/$groupId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  // Orders
  static Future<Map<String, dynamic>> adminGetOrders(String adminId,
      {String status = '', int page = 1}) async {
    final uri =
        Uri.parse('$baseUrl/api/admin/orders').replace(queryParameters: {
      if (status.isNotEmpty) 'status': status,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load orders');
  }

  static Future<Map<String, dynamic>> adminGetOrder(
      String adminId, String orderId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/orders/$orderId'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load order');
  }

  static Future<bool> adminUpdateOrderStatus(
      String adminId, String orderId, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/orders/$orderId/status'),
      headers: _adminHeaders(adminId),
      body: jsonEncode({'status': status}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteOrder(String adminId, String orderId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/orders/$orderId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  // Reviews
  static Future<Map<String, dynamic>> adminGetProductReviews(String adminId,
      {String productId = '', int page = 1}) async {
    final uri = Uri.parse('$baseUrl/api/admin/reviews/products')
        .replace(queryParameters: {
      if (productId.isNotEmpty) 'productId': productId,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load product reviews');
  }

  static Future<Map<String, dynamic>> adminGetStoreReviews(String adminId,
      {String storeId = '', String status = '', int page = 1}) async {
    final uri = Uri.parse('$baseUrl/api/admin/reviews/stores')
        .replace(queryParameters: {
      if (storeId.isNotEmpty) 'storeId': storeId,
      if (status.isNotEmpty) 'status': status,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load store reviews');
  }

  static Future<bool> adminDeleteProductReview(
      String adminId, String productId, String reviewId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/reviews/products/$productId/$reviewId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminUpdateStoreReviewStatus(
      String adminId, String storeId, String reviewId, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/reviews/stores/$storeId/$reviewId/status'),
      headers: _adminHeaders(adminId),
      body: jsonEncode({'status': status}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteStoreReview(
      String adminId, String storeId, String reviewId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/admin/reviews/stores/$storeId/$reviewId'),
      headers: _adminHeaders(adminId),
    );
    return res.statusCode == 200;
  }

  // Notifications
  static Future<bool> adminSendToAllUsers(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/notifications/all-users'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminSendToUser(
      String adminId, String userId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/notifications/user/$userId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    return res.statusCode == 201;
  }

  static Future<bool> adminSendToStoreFollowers(
      String adminId, String storeId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/notifications/store-followers/$storeId'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  static Future<bool> adminSendBySkinConcern(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/admin/notifications/skin-concern'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  // App Settings
  static Future<Map<String, dynamic>> adminGetSettings(String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/settings'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load settings');
  }

  static Future<Map<String, dynamic>> adminUpdateSettings(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/settings'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update settings');
  }

  // ── Admin Accounts ──────────────────────────────────────────────────────────
  static Future<List<dynamic>> adminGetAdmins(String adminId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/admin/admins'),
        headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load admins');
  }

  static Future<Map<String, dynamic>> adminCreateAdmin(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/admin/admins'),
        headers: _adminHeaders(adminId), body: jsonEncode(data));
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception(
        jsonDecode(res.body)['message'] ?? 'Failed to create admin');
  }

  static Future<bool> adminDeleteAdmin(String adminId, String targetId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/api/admin/admins/$targetId'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  static Future<bool> adminChangeAdminPassword(
      String adminId, String targetId, String newPassword) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/admins/$targetId/change-password'),
        headers: _adminHeaders(adminId),
        body: jsonEncode({'newPassword': newPassword}));
    return res.statusCode == 200;
  }

  // ── Store approval & badge ──────────────────────────────────────────────────
  static Future<bool> adminApproveStore(String adminId, String storeId) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/stores/$storeId/approve'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  static Future<bool> adminRejectStore(String adminId, String storeId) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/stores/$storeId/reject'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  static Future<bool> adminSetStoreBadge(String adminId, String storeId,
      String verificationLevel, bool isVerified) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/stores/$storeId/badge'),
        headers: _adminHeaders(adminId),
        body: jsonEncode({
          'verificationLevel': verificationLevel,
          'isVerified': isVerified
        }));
    return res.statusCode == 200;
  }

  // ── Groups (uses existing Group model) ─────────────────────────────────────
  static Future<Map<String, dynamic>> adminGetGroups(String adminId,
      {String search = '', String groupType = '', int page = 1}) async {
    final uri =
        Uri.parse('$baseUrl/api/admin/groups').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (groupType.isNotEmpty) 'groupType': groupType,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load groups');
  }

  static Future<Map<String, dynamic>> adminCreateGroup(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/api/admin/groups'),
        headers: _adminHeaders(adminId), body: jsonEncode(data));
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Failed to create group');
  }

  static Future<Map<String, dynamic>> adminUpdateGroup(
      String adminId, String groupId, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('$baseUrl/api/admin/groups/$groupId'),
        headers: _adminHeaders(adminId), body: jsonEncode(data));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update group');
  }

  static Future<bool> adminToggleGroupActive(
      String adminId, String groupId) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/groups/$groupId/toggle-active'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteGroup(String adminId, String groupId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/api/admin/groups/$groupId'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  /// Get posts belonging to a specific group (admin)
  static Future<Map<String, dynamic>> adminGetGroupPostsByGroup(
      String adminId, String groupId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/groups/$groupId/posts'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load group posts');
  }

  /// Get members of a specific group (admin)
  static Future<Map<String, dynamic>> adminGetGroupMembers(
      String adminId, String groupId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/groups/$groupId/members'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load group members');
  }

  // ── Group Posts (uses existing GroupPost model) ─────────────────────────────
  static Future<Map<String, dynamic>> adminGetGroupPosts(String adminId,
      {String search = '',
      String postType = '',
      String approvalStatus = '',
      int page = 1}) async {
    final uri =
        Uri.parse('$baseUrl/api/admin/group-posts').replace(queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (postType.isNotEmpty) 'postType': postType,
      if (approvalStatus.isNotEmpty) 'approvalStatus': approvalStatus,
      'page': '$page',
    });
    final res = await http.get(uri, headers: _adminHeaders(adminId));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load group posts');
  }

  static Future<bool> adminToggleGroupPostHidden(
      String adminId, String postId) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/group-posts/$postId/toggle-hidden'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  static Future<bool> adminSetGroupPostStatus(
      String adminId, String postId, String status) async {
    final res = await http.patch(
        Uri.parse('$baseUrl/api/admin/group-posts/$postId/approval-status'),
        headers: _adminHeaders(adminId),
        body: jsonEncode({'approvalStatus': status}));
    return res.statusCode == 200;
  }

  static Future<bool> adminDeleteGroupPost(
      String adminId, String postId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/api/admin/group-posts/$postId'),
        headers: _adminHeaders(adminId));
    return res.statusCode == 200;
  }

  // ── Admin store: reject with reason ────────────────────────────────────────
  static Future<bool> adminRejectStoreWithReason(
      String adminId, String storeId, String reason) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/admin/stores/$storeId/reject'),
      headers: _adminHeaders(adminId),
      body: jsonEncode({'rejectionReason': reason}),
    );
    return res.statusCode == 200;
  }

  // ── Store Request Flow ──────────────────────────────────────────────────────

  /// Upload a store image (logo or cover) before the store is created
  static Future<String?> uploadStoreImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/stores/upload-image'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body)['imageUrl'];
    return null;
  }

  /// Upload a verification document (image or PDF)
  static Future<String?> uploadVerificationDocument(File docFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/stores/upload-document'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('document', docFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body)['documentUrl'];
    return null;
  }

  /// Submit a new store request
  static Future<Map<String, dynamic>> submitStoreRequest({
    required String userId,
    required String storeName,
    required String city,
    String address = '',
    String phone = '',
    String description = '',
    String logoUrl = '',
    String coverImageUrl = '',
    String verificationDocumentUrl = '',
    String verificationDocumentType = 'other',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/stores/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'storeName': storeName,
        'city': city,
        'address': address,
        'phone': phone,
        'description': description,
        'logoUrl': logoUrl,
        'coverImageUrl': coverImageUrl,
        'verificationDocumentUrl': verificationDocumentUrl,
        'verificationDocumentType': verificationDocumentType,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception(
        jsonDecode(res.body)['message'] ?? 'Failed to submit store request');
  }

  /// Get the current user's store request/status
  static Future<Map<String, dynamic>> getMyStoreRequest(String userId) async {
    final res =
        await http.get(Uri.parse('$baseUrl/api/stores/my-request/$userId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('No store request found');
  }

  /// Resubmit a rejected store request
  static Future<Map<String, dynamic>> resubmitStoreRequest({
    required String storeId,
    required String storeName,
    required String city,
    String address = '',
    String phone = '',
    String description = '',
    String logoUrl = '',
    String coverImageUrl = '',
    String verificationDocumentUrl = '',
    String verificationDocumentType = 'other',
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/stores/request/$storeId/resubmit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'storeName': storeName,
        'city': city,
        'address': address,
        'phone': phone,
        'description': description,
        'logoUrl': logoUrl,
        'coverImageUrl': coverImageUrl,
        'verificationDocumentUrl': verificationDocumentUrl,
        'verificationDocumentType': verificationDocumentType,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(
        jsonDecode(res.body)['message'] ?? 'Failed to resubmit store request');
  }

  static Future<Map<String, dynamic>> getHomeSettings() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/admin/home-settings/public"),
      headers: {"Content-Type": "application/json"},
    );

    print("PUBLIC HOME SETTINGS STATUS: ${response.statusCode}");
    print("PUBLIC HOME SETTINGS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {};
  }

  // ── Public App Settings ────────────────────────────────────────────────────

  /// Fetches the public subset of AppSettings from the backend.
  /// Called on startup to check maintenance mode and feature flags.
  static Future<Map<String, dynamic>> getPublicSettings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/settings/public'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    // Return permissive defaults if request fails so app still works offline
    return {
      'maintenanceMode': false,
      'allowNewRegistrations': true,
      'allowSkinScans': true,
      'allowProductScans': true,
      'allowReviews': true,
      'allowGroupPosts': true,
    };
  }

  /// Save the user's FCM token on this device to the backend.
  static Future<void> saveFcmToken(String userId, String fcmToken) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/notifications/save-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': fcmToken}),
      );
    } catch (_) {}
  }

  /// Remove the FCM token on logout (optional but recommended).
  static Future<void> removeFcmToken(String userId, String fcmToken) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/notifications/remove-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': fcmToken}),
      );
    } catch (_) {}
  }

  // ── Welcome Screen Settings ────────────────────────────────────────────────

  /// Public — called by WelcomeScreen on load
  static Future<Map<String, dynamic>> getWelcomeSettings() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/welcome-settings/public'),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {};
  }

  /// Admin — load settings in dashboard
  static Future<Map<String, dynamic>> adminGetWelcomeSettings(
      String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/welcome-settings'),
      headers: _adminHeaders(adminId),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load welcome settings');
  }

  /// Admin — save settings
  static Future<Map<String, dynamic>> adminUpdateWelcomeSettings(
      String adminId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/admin/welcome-settings'),
      headers: _adminHeaders(adminId),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update welcome settings');
  }

  /// Admin — upload image or video for the welcome screen
  static Future<Map<String, dynamic>> adminUploadWelcomeMedia(
      String adminId, File mediaFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/welcome-settings/upload-media'),
    );
    request.headers['x-admin-id'] = adminId;
    request.files
        .add(await http.MultipartFile.fromPath('media', mediaFile.path));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200) return jsonDecode(body);
    throw Exception('Upload failed');
  }
}
