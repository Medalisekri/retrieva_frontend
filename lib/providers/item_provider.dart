import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retrieva/models/item_model.dart';
import 'package:retrieva/repositories/item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref)
{return ItemRepository();});

class ItemNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    return _repository.getItems();
  }

  ItemRepository get _repository => ref.read(itemRepositoryProvider);


  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Item>>(() async {
      return await _repository.getItems();
    }
    );
  }



  Future<void> addItem(Item item) async {
    final currentItems = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newItem = await _repository.addItem(item);
      return [...currentItems, newItem];
    }
    );
  }
}
class MyItemsNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    return _repository.getItems();
  }

  ItemRepository get _repository => ref.read(itemRepositoryProvider);

  Future<void> loadMyItems() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Item>>(() async {
      return await _repository.getMyItems();
    }
    );
  }

  Future<void> editMyItem(Item item) async {
    final currentItems = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Item>>(() async {
      final editedItem = await _repository.editItem(item);
      return [...currentItems, editedItem];
    }
    );
  }

  Future<void> deleteMyItem( Item item) async {
    final currentItems = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Item>>(() async {
      await _repository.deleteItem(item.id!);
      return currentItems.where((i) => i.id != item.id).toList();
    }
    );
  }

  Future<void> markAsResolved(Item item) async {
    final currentItems = state.value ?? [];
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<List<Item>>(() async {
      await _repository.markAsResolved(item.id!, {
        'status': 'resolved'
      });
      return currentItems.map((i) =>
      i.id == item.id ?
      i.copyWith(status: 'resolved')
          : i).toList();
    });
  }



}final itemNotifier = AsyncNotifierProvider<ItemNotifier , List<Item>>(
    ItemNotifier.new
);
// In your providers file
final myItemsNotifier =AsyncNotifierProvider<MyItemsNotifier,List<Item>>(MyItemsNotifier.new);
