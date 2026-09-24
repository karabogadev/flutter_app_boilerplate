import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/cache/cacheable_base_model.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel implements CacheableModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    String? name,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Convert to entity
  User toEntity() => User(
    id: id,
    email: email,
    name: name,
    avatarUrl: avatarUrl,
    createdAt: createdAt,
  );

  // Create from entity
  factory UserModel.fromEntity(User entity) => UserModel(
    id: entity.id,
    email: entity.email,
    name: entity.name,
    avatarUrl: entity.avatarUrl,
    createdAt: entity.createdAt,
  );
}

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required UserModel user,
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') String? refreshToken,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
