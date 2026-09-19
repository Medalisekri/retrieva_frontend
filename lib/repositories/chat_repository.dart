import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:retrieva/core/helper/auth_helper.dart';
import 'package:retrieva/models/chat_model.dart';

class ChatRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${dotenv.env['URL']}',
    headers:{ 'Content-Type' : 'application/json',}
  ))..interceptors.add(AuthInterceptor());


  Future<List<Conversation>> getConversations() async {
    final List<Conversation> conversations = [];
    try{
      final  response = await _dio.get('/chats/conversations/' );
      final List<dynamic> rawData = response.data as List<dynamic>;
      conversations.addAll(rawData.map((conv)=>Conversation.fromJson(conv as Map<String , dynamic>)).toList());
      return conversations;
    }catch(e){
      throw Exception('Something went wrong $e');
    }
  }

  Future<Conversation> getConversation(int conversationId) async{
    try{
      final response = await _dio.get('/chats/conversations/$conversationId');
      return Conversation.fromJson(response.data);
    }on DioException catch(e){
      throw Exception(e);
    }

  }

  Future<Conversation> createConversation({required int itemId , required int otherUserId}) async {
    try{
      final  response = await _dio.post('/chats/conversations/' ,
          data: {'item':itemId , 'participant2' : otherUserId});
      return Conversation.fromJson(response.data );
    } on DioException catch(e){
      if(e.response!.statusCode == 403){
        throw Exception('You need to login');
      }
      throw Exception('Something went wrong $e');
    }

  }

  Future<Message> sendMessage(
      {required int conversationId , required String? text , required String? imgUrl })  async {

    try{
      final  response = await _dio.post('/chats/conversations/$conversationId/messages/'  ,
          data: { 'text':text , 'img_url' : imgUrl});

      return Message.fromJson(response.data );
    }on DioException catch(e){
      throw Exception('Something went wrong $e');
    }

  }
  Future<List<Message>> getMessages(int conversationId) async {
    final List<Message> message = [];
    try{
      final  response = await _dio.get('/chats/conversations/$conversationId/messages/' );
      final List<dynamic> rawData = response.data as List<dynamic>;
      message.addAll(rawData.map((msg)=>Message.fromJson(msg as Map<String , dynamic>)).toList());
      return message;
    }catch(e){
      throw Exception('Something went wrong $e');
    }
  }

  Future<void> deleteMessage(int id) async {
    try{
       await _dio.delete('/chats/messages/$id/');
    }catch (e) {
      throw Exception('Something went wrong $e');
    }
  }

  Future<Conversation> blockOtherUser(int conversationId ) async {

    try{
      final  response = await _dio.post('/chats/conversations/$conversationId/block/' ,
         );
      return Conversation.fromJson(response.data );
    }catch (e) {
      throw Exception('Something went wrong $e');
    }
  }
}