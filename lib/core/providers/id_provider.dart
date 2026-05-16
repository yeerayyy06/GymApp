import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

typedef IdGenerator = String Function();

final idGeneratorProvider = Provider<IdGenerator>((ref) {
  const uuid = Uuid();
  return uuid.v4;
});
