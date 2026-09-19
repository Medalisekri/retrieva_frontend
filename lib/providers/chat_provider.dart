
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrieva/models/chat_model.dart';
import 'package:retrieva/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref){return ChatRepository();});

class ConversationNotifier extends AsyncNotifier<List<Conversation>> {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  Future<List<Conversation>> build() async {
    return await _repository.getConversations();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return await _repository.getConversations();
    });
  }


  Future<void> getConversations() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<List<Conversation>>(()async{
    return await  _repository.getConversations();
    });
  }

  Future<void> getConversation(int conversationId) async {
    final currentConversations = state.value ?? [];
    state = const AsyncLoading();
    state = await AsyncValue.guard<List<Conversation>>(()async{
     final newConv =   await  _repository.getConversation(conversationId);
       return [...currentConversations , newConv];
    });
  }

  Future<Conversation> createConversation({required int itemId, required int otherUserId}) async {
    final conversation = await _repository.createConversation(
      itemId: itemId,
      otherUserId: otherUserId,
    );
    final currentConversations = state.value ?? [];
    final alreadyExists = currentConversations.any((c) => c.id == conversation.id);
    if (!alreadyExists) {
      state = AsyncValue.data([...currentConversations, conversation]);
    }
    return conversation;
  }

  Future<void> updateLastMessage({
    required int conversationId,
    required String text,
    required DateTime time,
  }) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((conv) {
        if (conv.id == conversationId) {
          return conv.copyWith(lastMessage: text , lastMessageTime: time);

        }
        return conv;
      }).toList(),
    );
  }

  Future<void> blockOtherUser({ required int conversationId }) async{
final currentConversations = state.value ?? [];
state = await AsyncValue.guard<List<Conversation>>(()async{
  await _repository.blockOtherUser(conversationId);
  return currentConversations.where((i)=>i.id != conversationId).toList();
});
  }


}final conversationNotifier = AsyncNotifierProvider<ConversationNotifier , List<Conversation>>(ConversationNotifier.new);

class MessageNotifier extends AsyncNotifier<List<Message>> {
  Message? message;
@override
Future<List<Message>> build() async {
  return [];
}

ChatRepository get  _repository => ref.read(chatRepositoryProvider);

Future<void> getMessages(int id) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard<List<Message>>(()async{
    return await  _repository.getMessages(id);
  });
}

Future<void> sendMessage({required int conversationId , required String text , required String imgUrl }) async{
  final currentMessages = state.value ?? [];
  state = await AsyncValue.guard<List<Message>>(()async{
    final newMessage =   await _repository.sendMessage(conversationId: conversationId,
        text: text, imgUrl: imgUrl);
    final message = newMessage.copyWith(isMine: true);
    return [...currentMessages , message];
  });
}

Future<void> deleteMessage(Message message) async{
  final currentMessages = state.value ?? [];
state = await AsyncValue.guard<List<Message>>(()async{
  await _repository.deleteMessage(message.id);
return currentMessages.where((i)=>i.id != message.id).toList();
});

}

}final messageNotifier = AsyncNotifierProvider<MessageNotifier , List<Message>> (MessageNotifier.new)   ;