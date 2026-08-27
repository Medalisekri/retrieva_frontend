import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:retrieva/models/item_model.dart';

class ItemRepository  {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['ITEM_URL']!,
    headers: {'Content-Type': 'application/json'},
  ));

  Future<Options> get _authOptions async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
  }

Future<List<Item>> getItems() async {
  final List<Item> items = [];
  try{
  final  response = await _dio.get('/items/item/' , options: await _authOptions);
   if(response.statusCode!=200){
    throw Exception('Something went wrong ${response.statusMessage}');
  }
  final List<dynamic> rawData = response.data as List<dynamic>;
  items.addAll(rawData.map((item)=>Item.fromJson(item as Map<String , dynamic>)).toList());
  return items;
  }catch(e){
    throw Exception('Something went wrong $e');
  }

}
  Future<List<Item>> addItem(Item item) async {
    final List<Item> items = [];
    try{
      final  response = await _dio.post('/items/item/' , options: await _authOptions ,data: item);
      print(response.data);
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }
      final List<dynamic> rawData = response.data as List<dynamic>;
      items.addAll(rawData.map((item)=>Item.fromJson(item as Map<String , dynamic>)).toList());
      return items;
        }catch(e){
      throw Exception('Something went wrong $e');
    }

  }
}