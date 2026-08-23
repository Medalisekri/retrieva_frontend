import 'package:flutter_riverpod/legacy.dart';
import 'package:retrieva/models/item_model.dart';
import 'package:retrieva/repositories/item_repository.dart';

class ItemState{
      final List<Item> items;
      final bool isLoading;
      final String? errorMessage;

      ItemState({
        this.items = const[],
        this.isLoading = false,
        this.errorMessage,
});
}

class ItemProvider extends StateNotifier<ItemState> {
  ItemProvider():super(ItemState()){
    loadItems();
  }
  final _repository = ItemRepository();
  void loadItems()async {
    try{
      state = ItemState(items: [] , isLoading: true);
      final i = await _repository.getItems();
      state = ItemState(items: i , isLoading: false);
    }catch(e){
      state = ItemState(errorMessage: 'Something went wrong $e' , isLoading: false);
    }
  }
}final itemProvider = StateNotifierProvider<ItemProvider , ItemState>(
    (ref) => ItemProvider()
);