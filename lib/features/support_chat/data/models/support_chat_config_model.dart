// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_chat_config_model.freezed.dart';
part 'support_chat_config_model.g.dart';

@freezed
class SupportChatConfigModel with _$SupportChatConfigModel {
  const SupportChatConfigModel._();

  const factory SupportChatConfigModel({
    @JsonKey(name: 'baseUrl') required String baseUrl,
    @JsonKey(name: 'apiKeys') required Map<String, String> apiKeys,
    @JsonKey(name: 'enterprises') @Default([]) List<int> enterprises,
  }) = _SupportChatConfigModel;

  factory SupportChatConfigModel.fromJson(Map<String, dynamic> json) =>
      _$SupportChatConfigModelFromJson(json);

  bool isEnabledFor(int enterpriseId) => enterprises.contains(enterpriseId);

  String get posApiKey => apiKeys['pos'] ?? apiKeys['deliveries'] ?? '';
}
