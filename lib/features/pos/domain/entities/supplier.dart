import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final int id;
  final String name;
  final String? cuit;
  final bool isServiceProvider;

  const Supplier({
    required this.id,
    required this.name,
    this.cuit,
    required this.isServiceProvider,
  });

  @override
  List<Object?> get props => [id, name, cuit, isServiceProvider];
}
