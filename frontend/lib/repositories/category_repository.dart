import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final queryParams = <String, String>{};
    if (type != null) {
      queryParams['type'] = type;
    }
    final res = await ApiClient.get(ApiConstants.categories, queryParams: queryParams);
    return (res as List).map((c) => CategoryModel.fromJson(c)).toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String color = '#3B82F6',
    String icon = 'category',
  }) async {
    final res = await ApiClient.post(
      ApiConstants.categories,
      body: {
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
      },
    );
    return CategoryModel.fromJson(res);
  }

  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? color,
    String? icon,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (color != null) body['color'] = color;
    if (icon != null) body['icon'] = icon;

    final res = await ApiClient.put('${ApiConstants.categories}/$id', body: body);
    return CategoryModel.fromJson(res);
  }

  Future<void> deleteCategory(String id) async {
    await ApiClient.delete('${ApiConstants.categories}/$id');
  }
}

