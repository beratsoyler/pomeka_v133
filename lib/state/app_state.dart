import 'package:flutter/material.dart';

import '../models/formula_transfer_data.dart';

class AppState extends ChangeNotifier {
  FormulaTransferData? _pendingTransfer;

  FormulaTransferData? get pendingTransfer => _pendingTransfer;

  void setTransfer(FormulaTransferData data) {
    _pendingTransfer = data;
    notifyListeners();
  }

  FormulaTransferData? consumeTransfer({String? targetFormulaId}) {
    final transfer = _pendingTransfer;
    if (transfer == null) {
      return null;
    }
    if (targetFormulaId != null &&
        transfer.targetFormulaId != targetFormulaId) {
      return null;
    }
    _pendingTransfer = null;
    notifyListeners();
    return transfer;
  }

  void clearTransfer() {
    if (_pendingTransfer == null) {
      return;
    }
    _pendingTransfer = null;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null || scope.notifier == null) {
      throw FlutterError('AppStateScope not found in widget tree.');
    }
    return scope.notifier!;
  }
}
