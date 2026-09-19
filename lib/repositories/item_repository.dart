import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:retrieva/core/helper/auth_helper.dart';
import 'package:retrieva/models/item_model.dart';

import '../core/utils/items_cache.dart';

class ItemRepository  {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['URL']!,
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(AuthInterceptor());


  Future<List<Item>> getItems({
    int page = 1,
    String? type,
    String? category,
  }) async {
    try{
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': 20,
    };

    if (type != null && type.toLowerCase() != 'all') {
      queryParams['type'] = type.toLowerCase();
    }
    if (category != null && category != 'All') {
      queryParams['category'] = category;
    }

    final response = await _dio.get(
      '/items/item/',
      queryParameters: queryParams,
    );

    final data = response.data;
    final List<dynamic> rawData = data['results'] as List<dynamic>;
    await ItemsCache.save(rawData);
    return rawData.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }catch(e){
      final cached = await ItemsCache.load();
      if (cached != null) {
        return cached
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }}

  Future<List<Item>> getAllItems() async{
    try{
      final response =await _dio.get('/items/item/', queryParameters: {'page_size': 100} );
      final data = response.data;
      final List<dynamic> rawData = data['results'] as List<dynamic>;
      await ItemsCache.save(rawData);
      return rawData.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
    }catch(e){
      final cached = await ItemsCache.load();
      if (cached != null) {
        return cached
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  Future<List<Item>> getMyItems() async {
    final List<Item> items = [];
    try{
      final  response = await _dio.get('/items/my-items/' );
      final List<dynamic> rawData = response.data as List<dynamic>;
      await ItemsCache.save(rawData);
      items.addAll(rawData.map((item)=>Item.fromJson(item as Map<String , dynamic>)).toList());
      return items;

    }catch(e){
      final cached = await ItemsCache.load();
      if (cached != null) {
        return cached
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }


  }
  Future<Item> getItemDetail(int id) async {

    try{
      final  response = await _dio.get('/items/item/$id/');
      return Item.fromJson(response.data);
    }catch(e){
      throw Exception('Something went wrong $e');
    }
  }


  Future<Item> addItem(Item item) async {

    try{
      final  response = await _dio.post('/items/item/'  ,data: item.toJson());
      return Item.fromJson(response.data as Map<String , dynamic>);
    }on DioException catch (e) {
      if (e.response?.statusCode ==429) {
        final msg = e.response?.data['error'] ?? 'To many posts today';
        throw Exception(msg);
        }
      rethrow;
    }

  }
  Future<Item> editItem(Item item ) async {

    try{
      final  response = await _dio.patch('/items/item/${item.id}/' ,data: item.toJson());
      return Item.fromJson(response.data as Map<String , dynamic>);
    }catch (e) {
      throw Exception('Something went wrong $e');
    }

  }
  Future<void> deleteItem(int id) async {

    try{
      await _dio.delete('/items/item/$id/' ,);
    }catch (e) {
      throw Exception('Something went wrong $e');
    }

  }
  Future<void> markAsResolved(int id , Map<String , String> data) async {
    try{
      await _dio.patch('/items/item/$id/' , data: data);

    }catch (e) {
      throw Exception('Something went wrong $e');
    }

  }
}