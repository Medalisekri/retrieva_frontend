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
  Future<Item> addItem(Item item) async {

    try{
      final  response = await _dio.post('/items/item/' , options: await _authOptions ,data: item.toJson());
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }

      return Item.fromJson(response.data as Map<String , dynamic>);
        }on DioException catch (e) {
      print('PAYLOAD: ${e.requestOptions.data}');
      print('ERROR STATUS: ${e.response?.statusCode}');
      print('ERROR BODY: ${e.response?.data}');
      rethrow;
    }

  }
}