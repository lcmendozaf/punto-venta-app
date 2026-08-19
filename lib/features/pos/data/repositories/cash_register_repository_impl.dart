import 'package:punto_venta_app/features/pos/domain/entities/cash_register_status.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/cash_register_repository.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_remote_datasource.dart';

class CashRegisterRepositoryImpl implements CashRegisterRepository {
  final PdvRemoteDataSource remoteDataSource;

  CashRegisterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CashRegisterStatus> getStatus() async {
    final model = await remoteDataSource.fetchCashRegisterStatus();
    return model.toEntity();
  }

  @override
  Future<CashRegisterStatus> openRegister() async {
    const status = CashRegisterStatus(status: 'OPEN');
    final model = await remoteDataSource.updateCashRegisterStatus(status);
    return model.toEntity();
  }

  @override
  Future<CashRegisterStatus> closeRegister() async {
    const status = CashRegisterStatus(status: 'CLOSED');
    final model = await remoteDataSource.updateCashRegisterStatus(status);
    return model.toEntity();
  }
}
