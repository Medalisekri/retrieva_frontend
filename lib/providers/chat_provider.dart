
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrieva/models/chat_model.dart';
import 'package:retrieva/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref){return ChatRepository();});

class ConversationNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    return _repository.getConversations();
  }
  ChatRepository get  _repository => ref.read(chatRepositoryProvider);

  Future<void> getConversations() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Conversation>>(()async{
    return await  _repository.getConversations();
    });
  }
  Future<void> getConversation(int conversationId) async {
    final currentConversations = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Conversation>>(()async{
     final newConv =   await  _repository.getConversation(conversationId);
       return [...currentConversations , newConv];
    });
  }
  Future<void> createConversation({required int itemId , required int otherUserId}) async{
    final currentConversations = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Conversation>>(()async{
    final newConversation =   await _repository.createConversation(itemId: itemId, otherUserId: otherUserId);
    return [...currentConversations , newConversation];
    });

  }
  Future<void> blockOtherUser({ required int conversationId }) async{
final currentConversations = state.value ?? [];
state = const AsyncValue.loading();
state = await AsyncValue.guard<List<Conversation>>(()async{
  await _repository.blockOtherUser(conversationId);
  return currentConversations.where((i)=>i.id != conversationId.toString()).toList();
});
  }


}final conversationNotifier = AsyncNotifierProvider<ConversationNotifier , List<Conversation>>(ConversationNotifier.new);

class MessageNotifier extends AsyncNotifier<List<Message>> {
@override
Future<List<Message>> build() async {
  return _repository.getMessages(id);
}
late final int id;

ChatRepository get  _repository => ref.read(chatRepositoryProvider);

Future<void> getMessages() async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard<List<Message>>(()async{
    return await  _repository.getMessages(id);
  });
}
Future<void> sendMessage({required int conversationId , required String text , required String imgUrl }) async{
  final currentMessages = state.value ?? [];
  state = const AsyncValue.loading();
  state = await AsyncValue.guard<List<Message>>(()async{
    final newMessage =   await _repository.sendMessage(conversationId: conversationId,
        text: text, imgUrl: imgUrl);
    return [...currentMessages , newMessage];
  });

}
Future<void> deleteMessage(Message message) async{
  final currentMessages = state.value ?? [];
  state = const AsyncValue.loading();
state = await AsyncValue.guard<List<Message>>(()async{
  await _repository.deleteMessage(message.id!);
return currentMessages.where((i)=>i.id != message.id).toList();
});

}

}final messageNotifier = AsyncNotifierProvider<MessageNotifier , List<Message>> (MessageNotifier.new)   ;