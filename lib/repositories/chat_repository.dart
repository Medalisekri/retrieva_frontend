import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:retrieva/models/chat_model.dart';

class ChatRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${dotenv.env['URL']}',
    queryParameters:{ 'Content-Type' : 'application/json',}
  ));
  Future<Options> get  _authOptions async {
    final token = FirebaseAuth.instance.currentUser?.getIdToken();
    return Options( headers: {
      if(token != null) 'Authorization' :'Bearer $token}'}
    );
  }

  Future<List<Conversation>> getConversations() async {
    final List<Conversation> conversations = [];
    try{
      final  response = await _dio.get('/chats/conversations/' , options: await _authOptions);
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }
      final List<dynamic> rawData = response.data as List<dynamic>;
      conversations.addAll(rawData.map((conv)=>Conversation.fromJson(conv as Map<String , dynamic>)).toList());
      return conversations;
    }catch(e){
      throw Exception('Something went wrong $e');
    }
  }
  Future<Conversation> createConversation({required int itemId , required int otherUserId}) async {

    try{
      final  response = await _dio.post('/chats/conversations/' , options: await _authOptions ,
          data: {'item':itemId , 'participant2' : otherUserId});
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }

      return Conversation.fromJson(response.data as Map<String , dynamic>);
    }on DioException catch (e) {
      print('PAYLOAD: ${e.requestOptions.data}');
      print('ERROR STATUS: ${e.response?.statusCode}');
      print('ERROR BODY: ${e.response?.data}');
      rethrow;
    }

  }
  Future<Message> sendMessage(
      {required int conversationId , required String? text , required String? imgUrl ,required int id })  async {

    try{
      final  response = await _dio.post('/chats/conversations/$id/messages' , options: await _authOptions ,
          data: {'conversation': conversationId , 'text':text , 'img_url' : imgUrl});
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }

      return Message.fromJson(response.data as Map<String , dynamic>);
    }on DioException catch (e) {
      print('PAYLOAD: ${e.requestOptions.data}');
      print('ERROR STATUS: ${e.response?.statusCode}');
      print('ERROR BODY: ${e.response?.data}');
      rethrow;
    }

  }
  Future<List<Message>> getMessages(int id) async {
    final List<Message> message = [];
    try{
      final  response = await _dio.get('/chats/conversations/$id/messages' , options: await _authOptions);
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }
      final List<dynamic> rawData = response.data as List<dynamic>;
      message.addAll(rawData.map((msg)=>Message.fromJson(msg as Map<String , dynamic>)).toList());
      return message;
    }catch(e){
      throw Exception('Something went wrong $e');
    }
  }
  Future<Message> deleteMessage(int id) async {

    try{
      final  response = await _dio.delete('/chats/messages/$id' , options: await _authOptions);
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }

      return Message.fromJson(response.data as Map<String , dynamic>);
    }on DioException catch (e) {
      print('PAYLOAD: ${e.requestOptions.data}');
      print('ERROR STATUS: ${e.response?.statusCode}');
      print('ERROR BODY: ${e.response?.data}');
      rethrow;
    }

  }
  Future<Conversation> blockOtherUser(
      {required int id , required int conversationId , required int otherUserId}) async {

    try{
      final  response = await _dio.post('/chats/conversations/$id/block' , options: await _authOptions ,
          data: {'conversation':conversationId , 'participant2' : otherUserId});
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');
      if(response.statusCode!=200){
        throw Exception('Something went wrong ${response.statusMessage}');
      }

      return Conversation.fromJson(response.data as Map<String , dynamic>);
    }on DioException catch (e) {
      print('PAYLOAD: ${e.requestOptions.data}');
      print('ERROR STATUS: ${e.response?.statusCode}');
      print('ERROR BODY: ${e.response?.data}');
      rethrow;
    }

  }
}