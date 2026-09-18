import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});